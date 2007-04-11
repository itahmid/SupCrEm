###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/StaffProfile.pm.pl -> StaffProfile skin module           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::StaffProfile;

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
  my %in = (input => undef, error => "", @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Page  = $Dialog->SmallHeader(titles => "staff profile", colspan => 5);
     $Page .= $Dialog->LargeHeader(title => "User Information", colspan => 5);

  my $Body = $Dialog->TextBox(
    value     => $in{'input'}->{'STAFF_ACCOUNT'}->{'USERNAME'},
    subject   => "Username"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'STAFF_ACCOUNT'}->{'PASSWORD'},
    subject   => "Password"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'STAFF_ACCOUNT'}->{'NAME'},
    subject   => "Name"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'},
    subject   => "Email"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'STAFF_ACCOUNT'}->{'STATUS'} == 50 ? "Active" : "Inactive"),
    subject   => "Status"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'STAFF_ACCOUNT'}->{'LEVEL'} == 100 ? "Administrator" : "Support Staff"),
    subject   => "Level"
  );

  my $Categories;
  if ($in{'input'}->{'STAFF_ACCOUNT'}->{'CATEGORIES'} eq "*") {
    $Categories = "All";
  } elsif ($in{'input'}->{'STAFF_ACCOUNT'}->{'CATEGORIES'}) {
    foreach my $category (@{ $in{'input'}->{'ACCESS_CATEGORIES'} }) {
      $Categories .= $category->{'NAME'}."<br>";
    }
  }
  
  $Body .= $Dialog->TextBox(
    value     => $Categories,
    subject   => "Categories"
  );

  $Body .= $Dialog->TextArea(
    value     => $in{'input'}->{'STAFF_ACCOUNT'}->{'SIGNATURE'},
    subject   => "Signature"
  );

  $Body .= $Dialog->Button(buttons => [{ type => "submit", value => "Modify" }]);
  $Page .= $Dialog->Dialog(body => $Body, colspan => 5);
  
  $Page .= $Dialog->SmallHeader(
    titles => [
      { text => "", width => 1, nowrap => 1 },
      { text => "", width => "100%" },
      { text => "", width => 200, nowrap => 1 },
      { text => "", width => 200, nowrap => 1 },
      { text => "", width => 200, nowrap => 1 }
    ]
  );

  $Page .= $Dialog->LargeHeader(title => "Owned Tickets", colspan => 5);
  
  foreach my $ticket (@{ $in{'input'}->{'OWNED_TICKETS'} }) {
    my @fields;
    $fields[0] = $ticket->{'ID'};
    
    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=ViewModifyTicket&TID=$ticket->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $ticket->{'SUBJECT'};
    $fields[1] .= qq~</a>~;
    
    if ($ticket->{'AUTHOR'}) {    
      $fields[2]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$ticket->{'AUTHOR'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
      $fields[2] .= $in{'input'}->{'USER_ACCOUNTS'}->[$in{'input'}->{'USER_ACCOUNTS_IX'}->{$ticket->{'AUTHOR'}}]->{'NAME'}." (".$ticket->{'AUTHOR'}.")";
      $fields[2] .= qq~</a>~;
    } elsif ($ticket->{'GUEST_NAME'}) {
      $fields[2] .= $ticket->{'GUEST_NAME'}." (".$ticket->{'EMAIL'}.")";
    } else {
      $fields[2] .= $ticket->{'EMAIL'};
    }
    
    $fields[3] = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$ticket->{'CATEGORY'}}]->{'NAME'};
    $fields[4] = $ticket->{'CREATE_DATE'}." at ".$ticket->{'CREATE_TIME'};
    
    $Page .= $Dialog->Row(fields => \@fields);
  }
  
  if (scalar(@{ $in{'input'}->{'OWNED_TICKETS'} }) < 1) {
    $Page .= $Dialog->Row(fields => "This staff member doesn't own any tickets.", colspan => 5);
  }

  $Page .= $Dialog->LargeHeader(title => "Tickets Posted In", colspan => 5);
  
  foreach my $ticket (@{ $in{'input'}->{'POSTED_TICKETS'} }) {
    my @fields;
    $fields[0] = $ticket->{'ID'};
    
    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=ViewModifyTicket&TID=$ticket->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $ticket->{'SUBJECT'};
    $fields[1] .= qq~</a>~;
    
    if ($ticket->{'AUTHOR'}) {    
      $fields[2]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$ticket->{'AUTHOR'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
      $fields[2] .= $in{'input'}->{'USER_ACCOUNTS'}->[$in{'input'}->{'USER_ACCOUNTS_IX'}->{$ticket->{'AUTHOR'}}]->{'NAME'}." (".$ticket->{'AUTHOR'}.")";
      $fields[2] .= qq~</a>~;
    } elsif ($ticket->{'GUEST_NAME'}) {
      $fields[2] .= $ticket->{'GUEST_NAME'}." (".$ticket->{'EMAIL'}.")";
    } else {
      $fields[2] .= $ticket->{'EMAIL'};
    }
    
    $fields[3] = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$ticket->{'CATEGORY'}}]->{'NAME'};
    $fields[4] = $ticket->{'CREATE_DATE'}." at ".$ticket->{'CREATE_TIME'};
    
    $Page .= $Dialog->Row(fields => \@fields);
  }

  if (scalar(@{ $in{'input'}->{'POSTED_TICKETS'} }) < 1) {
    $Page .= $Dialog->Row(fields => "This staff member hasn't posted in any tickets.", colspan => 5);
  }
  
  $Page = $Dialog->Body($Page);
  $Page = $Dialog->Form(
    body    => $Page,
    hiddens => [
      { name => "USERNAME", value => $in{'input'}->{'STAFF_ACCOUNT'}->{'USERNAME'} },
      { name => "CP", value => "1" },
      { name => "action", value => "ViewModifyStaff" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Page = $Dialog->Page(body => $Page);
  
  return $Page;
}

1;