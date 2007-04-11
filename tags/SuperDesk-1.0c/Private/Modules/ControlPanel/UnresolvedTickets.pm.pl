###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/UnresolvedTickets.pm.pl -> UnresolvedTickets module            #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::UnresolvedTickets;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Mail.pm.pl";

use POSIX;
use strict;

require "ControlPanel/Output/UnresolvedTickets.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my (%Where, @Categories);
  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    @Categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    $Where{'ID'} = \@Categories;
  }

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => \%Where,
    MATCH   => "ANY"
  );
  
  unless ($SD::ADMIN{'LEVEL'} != 100 && $SD::QUERY{'CATEGORIES'} ne "*") {
    foreach my $category (@{ $Categories }) {
      push(@Categories, $category->{'ID'});
    }
  }
  
  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      CATEGORY  => \@Categories
    },
    MATCH   => "ANY",
    SORT    => "CREATE_SECOND",
    BY      => "A-Z"
  );

  my @Tickets;
  foreach my $ticket (@{ $Tickets }) {
    next if ($ticket->{'STATUS'} >= 60);
    next if ($ticket->{'OWNED_BY'} && $SD::ADMIN{'LEVEL'} != 100 && $ticket->{'OWNED_BY'} ne $SD::ADMIN{'USERNAME'});
    push(@Tickets, $ticket);
  }

  my $Page = $SD::QUERY{'Page'} || 1;
  my $TotalTickets = scalar(@Tickets);
  my $Start = ($Page - 1) * $GENERAL->{'TICKETS_PER_PAGE'};
  my $Finish = $Start + $GENERAL->{'TICKETS_PER_PAGE'} - 1;
     $Finish = $#Tickets if ($Finish > $#Tickets);

  @Tickets = @Tickets[$Start..$Finish];

  my (@UserAccounts, @StaffAccounts);
  foreach my $ticket (@Tickets) {
    push(@UserAccounts, $ticket->{'AUTHOR'}) if ($ticket->{'AUTHOR'});
    push(@StaffAccounts, $ticket->{'OWNED_BY'}) if ($ticket->{'OWNED_BY'});
  }

  my ($UserAccounts, $UserAccountsIndex);
  my ($StaffAccounts, $StaffAccountsIndex);
  
  if (scalar(@UserAccounts) >= 1) {
    ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
      TABLE   => "UserAccounts",
      WHERE   => {
        USERNAME  => \@UserAccounts
      },
      MATCH   => "ANY"
    );
  }

  if (scalar(@StaffAccounts) >= 1) {
    ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
      TABLE   => "StaffAccounts",
      WHERE   => {
        USERNAME  => \@StaffAccounts
      },
      MATCH   => "ANY"
    );
  }

  my %INPUT;

  $INPUT{'TOTAL_TICKETS'} = $TotalTickets;
  $INPUT{'TOTAL_PAGES'} = ceil($INPUT{'TOTAL_TICKETS'} / ($SD::QUERY{'FORM_TICKETS_PER_PAGE'} || 10));
  $INPUT{'TOTAL_PAGES'} = 1 if ($INPUT{'TOTAL_PAGES'} < 1);
  $INPUT{'PAGE'} = $Page;

  $INPUT{'TICKETS'} = \@Tickets;
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;
  $INPUT{'USER_ACCOUNTS_IX'} = $UserAccountsIndex;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;
  $INPUT{'STAFF_ACCOUNTS_IX'} = $StaffAccountsIndex;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::UnresolvedTickets->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

1;