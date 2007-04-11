###############################################################################
# SuperDesk                                                                   #
# Copyright (c) 2002-2007 Greg Nolle (http://greg.nolle.co.uk)                #
###############################################################################
# This program is free software; you can redistribute it and/or modify it     #
# under the terms of the GNU General Public License as published by the Free  #
# Software Foundation; either version 2 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# This program is distributed in the hope that it will be useful, but WITHOUT #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       #
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for   #
# more details.                                                               ##                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with this program; if not, write to the Free Software Foundation, Inc.,     #
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.                 #
###############################################################################
# Logout.pm.pl -> Logout module                                               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Logout;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";

use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/Logout.pm.pl";

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
  # Preparing data...                                                    #

  my $SID = $SD::QUERY{'SID'} || $SD::COOKIES{'SID'};
  
  if ($SID) {
    (
      $in{'DB'}->Delete(
        TABLE   => "Sessions",
        KEYS    => [$SID]
      )
    ) || &Error::Error("SD", MESSAGE => "Error deleting record. $in{'DB'}->{'ERROR'}");
  }

  $SD::COOKIES{'Username'} = "";
  $SD::COOKIES{'Password'} = "";
  $SD::COOKIES{'SID'} = "";

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::Logout->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show();
  
  return 1;
}

1;