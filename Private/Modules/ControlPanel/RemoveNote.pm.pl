###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveNote.pm.pl -> RemoveNote module                          #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use strict;

require "ControlPanel/Output/RemoveNote.pm.pl";

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'NID'}) {
    &Error::Error("CP", MESSAGE => "You didn't specify a Note ID (NID)");
  }

  my $Note = $in{'DB'}->BinarySelect(
    TABLE   => "Notes",
    KEY     => $SD::QUERY{'NID'}
  );
  unless ($Note) {
    &Error::Error("CP", MESSAGE => "The Note ID (NID) you specified is invalid");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE   => "Tickets",
    KEY     => $Note->{'TID'}
  );

  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $found;
    foreach my $category (@categories) {
      $found = 1 and last if ($category == $Ticket->{'CATEGORY'});
    }
    unless ($found) {
      &Error::Error("CP", MESSAGE => "You have insufficient rights to use this feature");
    }
  }

  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      TID => [$Ticket->{'ID'}]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "A-Z"
  );
  if ($Notes->[0]->{'ID'} == $SD::QUERY{'NID'}) {
    &Error::Error("CP", MESSAGE => "You can't delete the first note in a ticket");
  }

  #----------------------------------------------------------------------#
  # Deleting data...                                                     #

  (
    $in{'DB'}->Delete(
      TABLE   => "Notes",
      KEYS    => [$SD::QUERY{'NID'}]
    )
  ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");

  rmtree("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}");

  (
    $in{'DB'}->Update(
      TABLE   => "Tickets",
      VALUES  => {
        NOTES => "\${NOTES}--"
      },
      KEY     => $Note->{'TID'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error updating records. $in{'DB'}->{'ERROR'}");

  my %INPUT;

  my $Category = $in{'DB'}->BinarySelect(
    TABLE   => "Categories",
    KEY     => $Ticket->{'CATEGORY'}
  );

  if ($Ticket->{'AUTHOR'}) {
    my $UserAccount = $in{'DB'}->BinarySelect(
      TABLE   => "UserAccounts",
      KEY     => $Ticket->{'AUTHOR'}
    );
    $INPUT{'USER_ACCOUNT'} = $UserAccount;
  }

  $INPUT{'NOTE'} = $Note;
  $INPUT{'TICKET'} = $Ticket;
  $INPUT{'CATEGORY'} = $Category;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveNote->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;