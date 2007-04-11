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
# Action.pm.pl -> Action module                                               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Action;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";

use strict;

%SD::ACTIONS = (
  "SD"  => {
   # action                 => [module, subroutine]
    "Index"                 => ["Index", "show"],
    "Login"                 => ["Login", "show"],
    "DoLogin"               => ["Login", "do"],
    "Logout"                => ["Logout", "show"],
    "Register"              => ["Register", "show"],
    "DoRegister"            => ["Register", "do"],
    "CreateTicket"          => ["CreateTicket", "show"],
    "DoCreateTicket"        => ["CreateTicket", "do"],
    "ModifyTicket"          => ["ModifyTicket", "show"],
    "DoModifyTicket"        => ["ModifyTicket", "do"],
    "ModifyNote"            => ["ModifyNote", "show"],
    "DoModifyNote"          => ["ModifyNote", "do"],
    "ResolvedTickets"       => ["ResolvedTickets", "show"],
    "ModifyAccount"         => ["ModifyAccount", "show"],
    "DoModifyAccount"       => ["ModifyAccount", "do"],
    "StyleSheet"            => ["StyleSheet", "show"]
  },
  "CP"  => {
   # action                 => [module, subroutine]
    "Login"                 => ["Login", "show"],
    "DoLogin"               => ["Login", "do"],
    "Logout"                => ["Logout", "show"],
    "Title"                 => ["Title", "show"],
    "Menu"                  => ["Menu", "show"],
    "Index"                 => ["Index", "show"],
    "Summary"               => ["Summary", "show"],
    "GeneralOptions"        => ["GeneralOptions", "show"],
    "DoGeneralOptions"      => ["GeneralOptions", "do"],
    "SystemOptions"         => ["SystemOptions", "show"],
    "DoSystemOptions"       => ["SystemOptions", "do"],
    "StyleOptions"          => ["StyleOptions", "show"],
    "ViewStyleOptions"      => ["StyleOptions", "view"],
    "DoStyleOptions"        => ["StyleOptions", "do"],
    "CreateCategory"        => ["CreateCategory", "show"],
    "DoCreateCategory"      => ["CreateCategory", "do"],
    "ModifyCategory"        => ["ModifyCategory", "show"],
    "ViewModifyCategory"    => ["ModifyCategory", "view"],
    "DoModifyCategory"      => ["ModifyCategory", "do"],
    "RemoveCategories"      => ["RemoveCategories", "show"],
    "DoRemoveCategories"    => ["RemoveCategories", "do"],
    "CreateTicket"          => ["CreateTicket", "show"],
    "DoCreateTicket"        => ["CreateTicket", "do"],
    "ModifyTicket"          => ["ModifyTicket", "show"],
    "SearchModifyTicket"    => ["ModifyTicket", "search"],
    "ViewModifyTicket"      => ["ModifyTicket", "view"],
    "DoModifyTicket"        => ["ModifyTicket", "do"],
    "ModifyNote"            => ["ModifyNote", "show"],
    "DoModifyNote"          => ["ModifyNote", "do"],
    "DoRemoveNote"          => ["RemoveNote", "do"],
    "CreateMassNote"        => ["CreateMassNote", "show"],
    "SearchCreateMassNote"  => ["CreateMassNote", "search"],
    "ViewCreateMassNote"    => ["CreateMassNote", "view"],
    "DoCreateMassNote"      => ["CreateMassNote", "do"],
    "RemoveTickets"         => ["RemoveTickets", "show"],
    "SearchRemoveTickets"   => ["RemoveTickets", "search"],
    "DoRemoveTickets"       => ["RemoveTickets", "do"],
    "UnresolvedTickets"     => ["UnresolvedTickets", "show"],
    "CreateStaff"           => ["CreateStaff", "show"],
    "DoCreateStaff"         => ["CreateStaff", "do"],
    "StaffProfile"          => ["StaffProfile", "show"],
    "ModifyStaff"           => ["ModifyStaff", "show"],
    "ViewModifyStaff"       => ["ModifyStaff", "view"],
    "DoModifyStaff"         => ["ModifyStaff", "do"],
    "RemoveStaff"           => ["RemoveStaff", "show"],
    "DoRemoveStaff"         => ["RemoveStaff", "do"],
    "CreateUser"            => ["CreateUser", "show"],
    "DoCreateUser"          => ["CreateUser", "do"],
    "UserProfile"           => ["UserProfile", "show"],
    "ModifyUser"            => ["ModifyUser", "show"],
    "ViewModifyUser"        => ["ModifyUser", "view"],
    "DoModifyUser"          => ["ModifyUser", "do"],
    "RemoveUsers"           => ["RemoveUsers", "show"],
    "DoRemoveUsers"         => ["RemoveUsers", "do"],
    "CreateSkin"            => ["CreateSkin", "show"],
    "DoCreateSkin"          => ["CreateSkin", "do"],
    "RemoveSkins"           => ["RemoveSkins", "show"],
    "DoRemoveSkins"         => ["RemoveSkins", "do"],
    "EditTemplate"          => ["EditTemplate", "show"],
    "ListEditTemplate"      => ["EditTemplate", "list"],
    "ViewEditTemplate"      => ["EditTemplate", "view"],
    "DoEditTemplate"        => ["EditTemplate", "do"],
    "EditLanguage"          => ["EditLanguage", "show"],
    "ListEditLanguage"      => ["EditLanguage", "list"],
    "ViewEditLanguage"      => ["EditLanguage", "view"],
    "DoEditLanguage"        => ["EditLanguage", "do"],
    "Backup"                => ["Backup", "show"],
    "DoBackup"              => ["Backup", "do"],
    "Restore"               => ["Restore", "show"],
    "DoRestore"             => ["Restore", "do"],
    "ViewBackupLog"         => ["ViewBackupLog", "show"],
    "DoRemoveBackup"        => ["RemoveBackup", "do"],
    "ConvertDatabase"       => ["ConvertDatabase", "show"],
    "ViewConvertDatabase"   => ["ConvertDatabase", "view"],
    "DoConvertDatabase"     => ["ConvertDatabase", "do"],
    "InstallPackage"        => ["InstallPackage", "show"],
    "DoInstallPackage"      => ["InstallPackage", "do"],
    "Update"                => ["Update", "show"],
    "ViewUpdate"            => ["Update", "view"],
    "DoUpdate"              => ["Update", "do"]
  }
);

###############################################################################
# Main subroutine
sub Main {

  $| = 1;

  use CGI;

  require "Database.$SYSTEM->{'DB_TYPE'}.pm.pl";
  my $DB = new Database;

  $SD::CGI = CGI->new();

  &Standard::ParseForm();
  &Standard::ParseCookies();
  &Standard::SetSkin();
  &Standard::ProcessPlugins();

  if ($SYSTEM->{'INSTALLED'} == 0 && $SD::QUERY{'action'} ne "Install") {
    &Error::CGIError("SuperDesk has not been installed yet. Please run install.cgi before continuing.", "");
  } elsif ((-e "$SD::PATH/install.cgi" || -e "$SD::PATH/Private.tar") && ($SD::QUERY{'action'} ne "Install")) {
    &Error::CGIError("Please delete the install.cgi/pl and Private.tar files in the installation directory to avoid hacking.", "");
  }

  if ($SD::QUERY{'CP'}) {
    &ControlPanel(DB => $DB) and return 1;
  } else {
    &SuperDesk(DB => $DB) and return 1;
  }
}

###############################################################################
# SuperDesk subroutine
sub SuperDesk {
  my %in = (DB => undef, @_);

  my $Action = $SD::QUERY{'action'} || "Index";
  my $Page   = $SD::ACTIONS{'SD'}->{$Action};
  
  if (ref($Page) eq "CODE") {
    eval &$Page;
    if ($@) {
      &Error::CGIError("Error evaluating code reference. $@", "");
    } else {
      return 1;
    }
  } elsif ($Page) {
    require "$Page->[0].pm.pl";
    my $Source = eval($Page->[0]."->new()");
    eval("\$Source->".$Page->[1]."(DB => \$in{'DB'})");
    if ($@) {
      &Error::CGIError("Error evaluating the \"$Page->[1]\" subroutine in the \"$Page->[0]\" package. $@", "");
    } else {
      return 1;
    }
  } else {
    &Error::CGIError("Could not find action \"$Action\"", "");
  }
}

###############################################################################
# ControlPanel subroutine
sub ControlPanel {
  my %in = (DB => undef, @_);

  my $Action = $SD::QUERY{'action'} || "Index";
  my $Page   = $SD::ACTIONS{'CP'}->{$Action};

  if (ref($Page) eq "CODE") {
    eval &$Page;
    if ($@) {
      &Error::CGIError("Error evaluating code reference. $@", "");
    } else {
      return 1;
    }
  } elsif ($Page) {
    require "ControlPanel/$Page->[0].pm.pl";
    my $Source = eval("CP::".$Page->[0]."->new()");
    eval("\$Source->".$Page->[1]."(DB => \$in{'DB'})");
    if ($@) {
      &Error::CGIError("Error evaluating the \"$Page->[1]\" subroutine in the \"CP::$Page->[0]\" package. $@", "");
    } else {
      return 1;
    }
  } else {
    &Error::CGIError("Could not find action \"$Action\"", "");
  }
}

1;