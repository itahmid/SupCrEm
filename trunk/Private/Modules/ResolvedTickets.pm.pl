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
# ResolvedTickets.pm.pl -> ResolvedTickets module                             #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package ResolvedTickets;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/ResolvedTickets.pm.pl";

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

  &Authenticate::SD(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      AUTHOR  => [$SD::USER{'ACCOUNT'}->{'USERNAME'}],
      STATUS  => ["!=30", "!=40", "!=50"]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "A-Z"
  );

  my ($Categories, $CategoriesResolvedTickets) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'TICKETS'}       = $Tickets;
  $INPUT{'CATEGORIES'}    = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesResolvedTickets;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::ResolvedTickets->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

1;