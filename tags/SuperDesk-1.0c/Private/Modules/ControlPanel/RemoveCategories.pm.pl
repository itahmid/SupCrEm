###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveCategories.pm.pl -> RemoveCategories module              #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveCategories;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Variables.pm.pl";

use File::Path;
use strict;

require "ControlPanel/Output/RemoveCategories.pm.pl";

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

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'CATEGORIES'} = $Categories;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveCategories->new();

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

  my @CID = $SD::CGI->param('CID');

  if (scalar(@CID) < 1) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Deleting data...                                                     #

  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      CATEGORY  => \@CID
    },
    MATCH   => "ANY"
  );
  
  my @Tickets;
  foreach my $ticket (@{ $Tickets }) {
    push(@Tickets, $ticket->{'ID'});
  }
  
  my @Notes;
  if (scalar(@Tickets) >= 1) {
    my ($Notes, $NotesIndex) = $in{'DB'}->Query(
      TABLE   => "Notes",
      WHERE   => {
        TID => \@Tickets
      },
      MATCH   => "ANY"
    );
  
    foreach my $note (@{ $Notes }) {
      push(@Notes, $note->{'ID'});
    }
  }

  (
    $in{'DB'}->Delete(
      TABLE   => "Categories",
      KEYS    => \@CID
    )
  ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");

  if (scalar(@Tickets) >= 1) {
    (
      $in{'DB'}->Delete(
        TABLE   => "Tickets",
        KEYS    => \@Tickets
      )
    ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");
  }

  if (scalar(@Notes) >= 1) {
    (
      $in{'DB'}->Delete(
        TABLE   => "Notes",
        KEYS    => \@Notes
      )
    ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");
    
    foreach my $id (@Notes) {
      rmtree("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$id");
    }
  }

  my %Categories;
  foreach my $id (@CID) {
    $Categories{$id} = 1;
  }
  
  my %EmailAddresses;
  foreach my $key (keys %{ $GENERAL->{'EMAIL_ADDRESSES'} }) {
    $EmailAddresses{$key} = $GENERAL->{'EMAIL_ADDRESSES'}->{$key} unless ($Categories{ $GENERAL->{'EMAIL_ADDRESSES'}->{$key} });
  }
  
  my $Variables = Variables->new();
  (
    $Variables->Update(
      FILE      => "$SD::PATH/Private/Variables/General.pm",
      MODULE    => "General",
      VARIABLE  => "GENERAL",
      VALUES    => {
        EMAIL_ADDRESSES => \%EmailAddresses
      }
    )
  ) || &Error::Error("CP", MESSAGE => "Error updating variable file. $Variables->{'ERROR'}");

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveCategories->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do();
  
  return 1;
}

1;