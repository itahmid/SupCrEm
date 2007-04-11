###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ResolvedTickets.pm.pl -> ResolvedTickets skin module                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::ResolvedTickets;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use strict;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless ($self, $class);
}

sub DESTROY { }

###############################################################################
# show subroutine
sub show {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  foreach my $ticket (@{ $in{'input'}->{'TICKETS'} }) {
    $ticket->{'category'} = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$ticket->{'CATEGORY'}}];
  }

  my %FIELDS;

  $FIELDS{'tickets'} = $in{'input'}->{'TICKETS'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "ResolvedTickets.htm",
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
}

1;