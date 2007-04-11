###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Index.pm.pl -> Index skin module                         #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Index;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

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

  return <<HTML;
<html>
  <head>
    <title>SuperDesk Control Panel</title>
  </head>
  <frameset rows="50,*" framespacing="1" border="1" frameborder="1">
    <frame src="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=Title&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}" name="CPTITLE" marginwidth="0" marginheight="0" frameborder="0" framespacing="0" scrolling="no" noresize>
    <frameset cols="20%,80%">
      <frame src="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=Menu&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}" name="CPMENU" marginwidth="0" marginheight="0" scrolling="yes">
      <frame src="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=Summary&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}" name="CPBODY" frameborder="1" framespacing="1" scrolling="yes">
    </frameset>
  </frameset>
</html>
HTML

}

1;