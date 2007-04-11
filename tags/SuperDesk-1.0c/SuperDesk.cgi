#!/usr/bin/perl
#^^^^^^^^^^^^^^ Change this to the location of Perl                           #
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
# SuperDesk.cgi -> Main script                                                #
###############################################################################
# All configuration is performed in the Control Panel. Please do not edit the #
# script directly.                                                            #
###############################################################################
package SD;

BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File SDBM_File) }

BEGIN {
  #############################################################################
  # Change this to the path to SuperDesk if the script fails.                 #
  $SD::PATH = "."; # < < < < < < < < < < < < < < < < < < < < < < < < < < < < <#
  #############################################################################
  # DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                       #
  #############################################################################

  my $ScriptName = $0;
     $ScriptName =~s/\\/\//g;
     $ScriptName =~s/^.*\/([^\/]+)$/$1/g;

  unless (-e $SD::PATH."/".$ScriptName) {
    foreach my $path ( $0, $ENV{'SCRIPT_FILENAME'}, $ENV{'PATH_TRANSLATED'} ) {
      $path =~s/\\/\//g;
      $path =~s/^(.*)\/[^\/]+$/$1/g;
      if (-e $path."/".$ScriptName) {
        $SD::PATH = $path and last;
      }
    }
  }

  unshift (@INC, "$SD::PATH");
  unshift (@INC, "$SD::PATH/Private");
  unshift (@INC, "$SD::PATH/Private/Variables");
  unshift (@INC, "$SD::PATH/Private/Modules");
  unshift (@INC, "$SD::PATH/Private/Modules/Libraries");
}

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }

BEGIN { %SD::GLOBAL = ("SKIN" => $GENERAL->{'SKIN'}); }

###############################################################################
# Main script: #
################

require "Error.pm.pl";
require "Version.pm.pl";

eval {
  require "Action.pm.pl";
  &Action::Main();
} || &Error::CGIError("Couldn't execute your request. $@", "");

exit;
###############################################################################

1;