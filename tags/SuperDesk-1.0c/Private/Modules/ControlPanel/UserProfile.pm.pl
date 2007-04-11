###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/UserProfile.pm.pl -> UserProfile module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::UserProfile;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/UserProfile.pm.pl";

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
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'USERNAME'}) {
    &Error::Error("CP", MESSAGE => "You didn't specify a user's USERNAME");
  }
  
  my $UserAccount = $in{'DB'}->BinarySelect(
    TABLE => "UserAccounts",
    KEY   => $SD::QUERY{'USERNAME'}
  );
  unless ($UserAccount) {
    &Error::Error("CP", MESSAGE => "The USERNAME you specified is invalid");
  }

  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      AUTHOR  => [$SD::QUERY{'USERNAME'}]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "Z-A"
  );

  my ($Categories, $CategoriesIndex);
  
  if (scalar(@{ $Tickets }) >= 1) {
    my @categories;
    foreach my $ticket (@{ $Tickets }) {
      push(@categories, $ticket->{'CATEGORY'});
    }
  
    ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
      TABLE   => "Categories",
      WHERE   => {
        ID  => \@categories
      },
      MATCH   => "ANY"
    );
  }

  my %INPUT;
  
  $INPUT{'USER_ACCOUNT'}  = $UserAccount;
  $INPUT{'TICKETS'}       = $Tickets;
  $INPUT{'CATEGORIES'}    = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;  

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::UserProfile->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT, error => $in{'ERROR'});
  
  return 1;
}

1;