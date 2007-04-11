###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Menu.pm.pl -> Menu skin module                           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Menu;

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

  my %Sections = (
    "TOP"       => [0, "", [
      { title => "control panel index", action => "Summary" },
      { title => "superdesk index", url => $SYSTEM->{'SCRIPT_URL'} },
      { title => "superdesk online manual", url => "http://www.plasmapulse.com/?sc=SDManual" },
      { title => "superdesk home page", url => "http://www.plasmapulse.com/?sc=SuperDesk" }
    ]],
    "GENERAL"   => [1, "General Settings", [
      { title => "system options", action => "SystemOptions" },
      { title => "general options", action => "GeneralOptions" },
      { title => "style options", action => "StyleOptions" },
      { title => "logout ($SD::ADMIN{'USERNAME'})", action => "Logout", target => "_top" }
    ]],
    "CATEGORY"  => [2, "Category Management", [
      { title => "create a new category", action => "CreateCategory" },
      { title => "modify a category", action => "ModifyCategory" },
      { title => "remove categories", action => "RemoveCategories" }
    ]],
    "TICKET"    => [3, "Ticket Management", [
      { title => "create a new ticket", action => "CreateTicket" },
      { title => "modify/view/add to ticket", action => "ModifyTicket" },
      { title => "create a mass note", action => "CreateMassNote" },
      { title => "remove tickets", action => "RemoveTickets" },
      { title => "unresolved tickets", action => "UnresolvedTickets" }
    ]],
    "USER"      => [4, "User Management", [
      { title => "create a new user", action => "CreateUser" },
      { title => "modify a user", action => "ModifyUser" },
      { title => "remove users", action => "RemoveUsers" }
    ]],
    "STAFF"     => [5, "Staff Management", [
      { title => "create a new staff account", action => "CreateStaff" },
      { title => "modify a staff account", action => "ModifyStaff" },
      { title => "remove staff accounts", action => "RemoveStaff" }
    ]],
    "SKINS"     => [6, "Skins", [
      { title => "create a new skin", action => "CreateSkin" },
      { title => "remove skins", action => "RemoveSkins" },
      { title => "edit template", action => "EditTemplate" },
      { title => "edit language", action => "EditLanguage" }
    ]],
    "UTILITIES" => [7, "Utilities", [
      { title => "backup database", action => "Backup" },
      { title => "restore database", action => "Restore" },
      { title => "convert database", action => "ConvertDatabase" },
      { title => "install package", action => "InstallPackage" },
      { title => "update superdesk", action => "Update" }
    ]]
  );
  
  foreach my $section (keys %SD::CPMENU) {
    if ($Sections{$section}) {
      foreach my $item (@{ $SD::CPMENU{$section} }) {
        push(@{ $Sections{$section}->[2] }, $item);
      }
    } else {
      $Sections{$section} = $SD::CPMENU{$section};
    }
  }

  my @Keys = keys(%Sections);
     @Keys = sort { $Sections{$a}->[0] <=> $Sections{$b}->[0] } @Keys;

  my $Body = qq~<table border="0" cellpadding="4" cellspacing="1" width="100%" bgcolor="#333333">\n~;
  
  foreach my $key (@Keys) {
    my $section = $Sections{$key};
    if ($section->[1]) {
      $Body .= qq~  <tr class="large-header">\n~;
      $Body .= qq~    <td width="100%"><font class="large-header">$section->[1]</font></td>\n~;
      $Body .= qq~  </tr>\n~;
    }
    foreach my $item (@{ $section->[2] }) {
      $Body .= qq~  <tr class="body">\n~;
      $Body .= qq~    <td width="100%"><font class="body">~;
      if ($item->{'action'}) {
        $Body .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=$item->{'action'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}"~;
        $Body .= qq~ target="~.($item->{'target'} || "CPBODY").qq~"~;
        $Body .= qq~>~;
      } elsif ($item->{'url'}) {
        $Body .= qq~<a href="$item->{'url'}"~;
        $Body .= qq~ target="~.($item->{'target'} || "CPBODY").qq~"~;
        $Body .= qq~>~;
      }
      $Body .= qq~$item->{'title'}~;
      $Body .= qq~</a>~ if ($item->{'action'} || $item->{'url'});
      $Body .= qq~</font></td>\n~;
      $Body .= qq~  </tr>\n~;
    }
  }
  
  $Body .= qq~</table>\n~;

  $Body = $Dialog->Page(
    body          => $Body,
    "body-extra"  => qq~marginheight="0" marginwidth="0" topmargin="0" leftmargin="0"~,
    "body-style"  => qq~padding-top: 0px; padding-right: 0px; padding-left: 0px; padding-bottom: 0px; margin: 0px~
  );
  
  return $Body;
}

1;