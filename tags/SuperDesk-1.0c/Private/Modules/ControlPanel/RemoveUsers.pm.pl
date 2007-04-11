###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveUsers.pm.pl -> RemoveUsers module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveUsers;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/RemoveUsers.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_REMOVE_USERS'});

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
    SORT    => "USERNAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveUsers->new();

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

  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_REMOVE_USERS'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @USERNAME = $SD::CGI->param('USERNAME');

  if (scalar(@USERNAME) < 1) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
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
      TABLE   => "UserAccounts",
      KEYS    => \@USERNAME
    )
  ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");

  my %INPUT;
  
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveUsers->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;