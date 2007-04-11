###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/RemoveNote.pm.pl -> RemoveNote skin module               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::RemoveNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use HTML::Dialog;
use strict;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless ($self, $class);
}

sub DESTROY { }

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The selected note has been removed.");

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "remove note").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;