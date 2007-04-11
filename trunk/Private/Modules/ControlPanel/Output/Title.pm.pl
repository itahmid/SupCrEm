###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Title.pm.pl -> Title skin module                         #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Title;

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
# show subroutine
sub show {
  my $self = shift;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  
  my $Body = <<HTML;
<table cellpadding="0" cellspacing="0" border="0" width="100%" background="http://www.plasmapulse.com/images/offsite/sd/title_bg.gif">
  <tr>
    <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/sd/title.gif" border="0"></td>
    <td width="10" nowrap></td>
    <td width="100%"><font class="sub-body">SuperDesk [$SD::VERSION] Standard Edition</font></td>
  </tr>
</table>
HTML
  
  $Body = $Dialog->Page(body => $Body, "body-extra" => qq~bgcolor="#EEEEEE" marginheight="0" marginwidth="0" topmargin="0" leftmargin="0" rightmargin="0" bottommargin="0"~, "body-style" => qq~padding-left: 0px; padding-right: 0px; padding-top: 0px; padding-bottom: 0px; margin: 0px; background-color: #EEEEEE~);
  
  return $Body;
}

1;