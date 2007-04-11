###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/Index.pm.pl -> Index module                                    #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::Index;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/Index.pm.pl";

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
  # Printing page...                                                     #

  my $Skin = Skin::CP::Index->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show();
  
  return 1;
}

1;