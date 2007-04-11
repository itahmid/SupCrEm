###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveStaff.pm.pl -> RemoveStaff module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveStaff;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/RemoveStaff.pm.pl";

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# show subroutine
sub show {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "USERNAME",
    BY      => "A-Z"
  );

  my @StaffAccounts;
  foreach my $staff (@{ $StaffAccounts }) {
    push(@StaffAccounts, $staff) unless ($staff->{'USERNAME'} eq $SD::ADMIN{'USERNAME'});
  }

  my %INPUT;
  
  $INPUT{'STAFF_ACCOUNTS'} = \@StaffAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveStaff->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @USERNAME = $SD::CGI->param('USERNAME');

  if (scalar(@USERNAME) < 1) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    WHERE   => {
      USERNAME  => \@USERNAME
    },
    MATCH   => "ANY",
    SORT    => "USERNAME",
    BY      => "A-Z"
  );

  #----------------------------------------------------------------------#
  # Deleting data...                                                     #

  (
    $in{'DB'}->Delete(
      TABLE   => "StaffAccounts",
      KEYS    => \@USERNAME
    )
  ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");

  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      OWNED_BY  => \@USERNAME
    },
    MATCH   => "ANY"
  );
  
  foreach my $ticket (@{ $Tickets }) {
    (
      $in{'DB'}->Update(
        TABLE   => "Tickets",
        VALUES  => {
          OWNED_BY  => ""
        },
        KEY     => $ticket->{'ID'}
      )
    ) || &Error::Error("CP", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");
  }

  my %INPUT;
  
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveStaff->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;