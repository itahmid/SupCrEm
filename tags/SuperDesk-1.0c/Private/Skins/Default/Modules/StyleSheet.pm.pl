###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/StyleSheet.pm.pl -> StyleSheet skin module                            #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::StyleSheet;

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

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "Interface/StyleSheet.htm",
    STANDARD  => 1
  );
}

1;