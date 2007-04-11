###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/StaffProfile.pm.pl -> StaffProfile module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::StaffProfile;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/StaffProfile.pm.pl";

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
  if ($SD::QUERY{'USERNAME'}) {
    unless ($SD::ADMIN{'LEVEL'} == 100 || $SD::ADMIN{'USERNAME'} eq $SD::QUERY{'USERNAME'}) {
      &Error::Error("CP", MESSAGE => "You have insufficient rights to access this feature");
    }
  }

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'USERNAME'}) {
    &Error::Error("CP", MESSAGE => "You didn't specify a staff member's USERNAME");
  }
  
  my $StaffAccount = $in{'DB'}->BinarySelect(
    TABLE => "StaffAccounts",
    KEY   => $SD::QUERY{'USERNAME'}
  );
  unless ($StaffAccount) {
    &Error::Error("CP", MESSAGE => "The USERNAME you specified is invalid");
  }

  my $AccessCategories;
  if ($StaffAccount->{'CATEGORIES'} && $StaffAccount->{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $StaffAccount->{'CATEGORIES'});
    ($AccessCategories, undef) = $in{'DB'}->Query(
      TABLE   => "Categories",
      WHERE   => {
        ID  => \@categories
      },
      MATCH   => "ANY",
      SORT    => "NAME",
      BY      => "A-Z"
    )
  }

  my ($OwnedTickets, $OwnedTicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      OWNED_BY  => [$SD::QUERY{'USERNAME'}]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "Z-A"
  );

  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      AUTHOR      => [$SD::QUERY{'USERNAME'}],
      AUTHOR_TYPE => ["STAFF"],
    },
    MATCH   => "ALL"
  );
  
  my ($PostedTickets, $UserAccounts, $UserAccountsIndex);
  if (scalar(@{ $Notes }) >= 1) {
    my @tickets;
    foreach my $note (@{ $Notes }) {
      push(@tickets, $note->{'TID'});
    }
    
    ($PostedTickets, undef) = $in{'DB'}->Query(
      TABLE   => "Tickets",
      WHERE   => {
        ID  => \@tickets
      },
      MATCH   => "ANY",
      SORT    => "CREATE_SECOND",
      BY      => "Z-A"
    );
    
    if (scalar(@{ $PostedTickets }) >= 1) {
      my @authors;
      foreach my $ticket (@{ $PostedTickets }) {
        push(@authors, $ticket->{'AUTHOR'});
      }
      
      ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
        TABLE   => "UserAccounts",
        WHERE   => {
          USERNAME  => \@authors
        },
        MATCH   => "ANY"
      );
    }
  }

  my ($Categories, $CategoriesIndex);
  
  if (scalar(@{ $OwnedTickets }, @{ $PostedTickets }) >= 1) {
    my @categories;
    foreach my $ticket (@{ $OwnedTickets }, @{ $PostedTickets }) {
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
  
  $INPUT{'STAFF_ACCOUNT'}     = $StaffAccount;
  $INPUT{'ACCESS_CATEGORIES'} = $AccessCategories;
  $INPUT{'OWNED_TICKETS'}     = $OwnedTickets;
  $INPUT{'POSTED_TICKETS'}    = $PostedTickets;
  $INPUT{'CATEGORIES'}        = $Categories;
  $INPUT{'CATEGORIES_IX'}     = $CategoriesIndex;
  $INPUT{'USER_ACCOUNTS'}     = $UserAccounts;
  $INPUT{'USER_ACCOUNTS_IX'}  = $UserAccountsIndex;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::StaffProfile->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT, error => $in{'ERROR'});
  
  return 1;
}

1;