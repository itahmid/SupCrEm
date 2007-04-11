###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/UnresolvedTickets.pm.pl -> UnresolvedTickets skin module #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::UnresolvedTickets;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use HTML::Dialog;
use HTML::Form;
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
  my $Form = HTML::Form->new();

  my $Body = $Dialog->SmallHeader(
    titles => [
      { text => "id", width => 1, nowrap => 1 },
      { text => "subject", width => "100%" },
      { text => "notes", width => 40, nowrap => 1 },
      { text => "status", width => 80, nowrap => 1 },
      { text => "author", width => 180, nowrap => 1 },
      { text => "owned by", width => 180, nowrap => 1 },
      { text => "category", width => 180, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Unresolved Tickets", colspan => 7);
  
  foreach my $ticket (@{ $in{'input'}->{'TICKETS'} }) {
    my @fields;
    $fields[0] = $ticket->{'ID'};
    
    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=ViewModifyTicket&TID=$ticket->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $ticket->{'SUBJECT'};
    $fields[1] .= qq~</a> <small>(<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=DoRemoveTickets&TID=$ticket->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">del</a>)</small>~;
    
    $fields[2] = $ticket->{'NOTES'};
    
    $fields[3] = $GENERAL->{'STATUS'}->{ $ticket->{'STATUS'} };
    
    if ($ticket->{'AUTHOR'}) {
      $fields[4]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$ticket->{'AUTHOR'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
      $fields[4] .= $in{'input'}->{'USER_ACCOUNTS'}->[$in{'input'}->{'USER_ACCOUNTS_IX'}->{$ticket->{'AUTHOR'}}]->{'NAME'}." (".$ticket->{'AUTHOR'}.")";
      $fields[4] .= qq~</a>~;
    } elsif ($ticket->{'GUEST_NAME'}) {
      $fields[4] = $ticket->{'GUEST_NAME'}." (".$ticket->{'EMAIL'}.")";
    } else {
      $fields[4] = $ticket->{'EMAIL'}
    }
    
    if ($ticket->{'OWNED_BY'}) {
      $fields[5] = $in{'input'}->{'STAFF_ACCOUNTS'}->[$in{'input'}->{'STAFF_ACCOUNTS_IX'}->{$ticket->{'OWNED_BY'}}]->{'NAME'}." (".$ticket->{'OWNED_BY'}.")";
    } else {
      $fields[5] = "--- Nobody ---";
    }
    
    $fields[6] = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$ticket->{'CATEGORY'}}]->{'NAME'};
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value  = qq~<table cellpadding="0" cellspacing="0" width="100%" border="0">~;
     $value .= qq~<tr><td align="right">~;
     $value .= qq~<font class="row"><small>~;

  my $QueryString;
  foreach my $key (keys %SD::QUERY) {
    $QueryString .= "$key=$SD::QUERY{$key}&" unless ($key eq "Page");
  }
  
  $value .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?~.$QueryString.qq~Page=~.($in{'input'}->{'PAGE'} - 1).qq~">~ unless ($in{'input'}->{'PAGE'} == 1);
  $value .= qq~&lt; Prev~;
  $value .= qq~</a>~ unless ($in{'input'}->{'PAGE'} == 1);
  $value .= qq~ | ~;
  
  for (my $h = 1; $h <= $in{'input'}->{'TOTAL_PAGES'}; $h++) {
    if ($h == $in{'input'}->{'PAGE'}) {
      $value .= $h." ";
    } else {
      $value .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?~.$QueryString.qq~Page=$h">$h</a> ~;
    }
  }
  
  $value .= qq~| ~;
  $value .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?~.$QueryString.qq~Page=~.($in{'input'}->{'PAGE'} + 1).qq~">~ unless ($in{'input'}->{'PAGE'} == $in{'input'}->{'TOTAL_PAGES'});
  $value .= qq~Next &gt;~;
  $value .= qq~</a>~ unless ($in{'input'}->{'PAGE'} == $in{'input'}->{'TOTAL_PAGES'});
  $value .= qq~</small></font></td></tr></table>~;
  
  $Body .= $Dialog->Row(fields => $value, colspan => 7);

  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;