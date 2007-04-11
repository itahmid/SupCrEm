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
# Login.pm.pl -> Login module                                                 #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Login;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/Login.pm.pl";

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
  # Printing page...                                                     #

  my $Skin = Skin::Login->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);
  
  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::SD(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  if ($SD::QUERY{'FORM_STORE_DETAILS'}) {
    $SD::COOKIES{'Username'} = $SD::USER{'ACCOUNT'}->{'USERNAME'};
    $SD::COOKIES{'Password'} = $SD::USER{'ACCOUNT'}->{'PASSWORD'};
  }
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::Login->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do();
  
  return 1;
}

1;