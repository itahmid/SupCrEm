###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Summary.pm.pl -> Summary skin module                     #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Summary;

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
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->TextBox(
    subject => "Unresolved Tickets",
    value   => ($in{'input'}->{'TOTALS'}->{'UNRESOLVED_TICKETS'} ? qq~<b><a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UnresolvedTickets&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">$in{'input'}->{'TOTALS'}->{'UNRESOLVED_TICKETS'}</a></b>~ : "0")
  );
  
  $Body .= $Dialog->TextBox(
    subject => "Resolved Tickets",
    value   => ($in{'input'}->{'TOTALS'}->{'RESOLVED_TICKETS'} ? qq~<b><a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=SearchModifyTicket&FORM_STATUS=60&FORM_STATUS=70&FORM_BOOLEAN=AND&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">$in{'input'}->{'TOTALS'}->{'RESOLVED_TICKETS'}</a></b>~ : "0")
  );
  
  $Body .= $Dialog->TextBox(
    subject => "Total Tickets",
    value   => $in{'input'}->{'TOTALS'}->{'TICKETS'}
  );
  
  $Body .= $Dialog->TextBox(
    subject => "Total Categories",
    value   => $in{'input'}->{'TOTALS'}->{'CATEGORIES'}
  );

  $Body .= $Dialog->TextBox(
    subject => "Total User Accounts",
    value   => $in{'input'}->{'TOTALS'}->{'USERS'}
  );

  $Body .= $Dialog->TextBox(
    subject => "Total Staff Accounts",
    value   => $in{'input'}->{'TOTALS'}->{'STAFF'}
  );

  my $Page  = $Dialog->SmallHeader(titles => "summary");
     $Page .= $Dialog->LargeHeader(title => "Statistics");
     $Page .= $Dialog->Dialog(body => $Body);

  $Body = $Dialog->TextBox(
    subject => "Current Version",
    value   => $SD::VERSION
  );
  
  my $LatestVersion;
  if ($in{'input'}->{'LATEST_VERSION'}) {
    if ($in{'input'}->{'LATEST_VERSION'} eq $SD::VERSION) {
      $LatestVersion = $in{'input'}->{'LATEST_VERSION'};
    } else {
      $LatestVersion = qq~<b><a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=Update&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">$in{'input'}->{'LATEST_VERSION'}</a></b>~;
    }
  } else {
    $LatestVersion = "Unknown";
  }
  $Body .= $Dialog->TextBox(
    subject => "Latest Version",
    value   => $LatestVersion
  );
  
  $Page .= $Dialog->LargeHeader(title => "Versions");
  $Page .= $Dialog->Dialog(body => $Body);

  $Page = $Dialog->Body($Page);
  $Page = $Dialog->Page(body => $Page);
  
  return $Page;
}

1;