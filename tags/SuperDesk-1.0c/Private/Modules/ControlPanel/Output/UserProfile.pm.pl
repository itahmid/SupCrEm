###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/UserProfile.pm.pl -> UserProfile skin module             #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::UserProfile;

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

  my $Page  = $Dialog->SmallHeader(titles => "user profile", colspan => 4);
     $Page .= $Dialog->LargeHeader(title => "User Information", colspan => 4);

  my $Body = $Dialog->TextBox(
    value     => $in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'},
    subject   => "Username"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'USER_ACCOUNT'}->{'PASSWORD'},
    subject   => "Password"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'USER_ACCOUNT'}->{'NAME'},
    subject   => "Name"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'USER_ACCOUNT'}->{'EMAIL'},
    subject   => "Email"
  );

  my @emails;
  foreach my $email (split(/\|/, $in{'input'}->{'USER_ACCOUNT'}->{'OTHER_EMAILS'})) {
    push(@emails, $email) if ($email);
  }
  
  $Body .= $Dialog->TextBox(
    value     => join("<br>", @emails),
    subject   => "Other Email Addresses"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'USER_ACCOUNT'}->{'URL'},
    subject   => "Website URL"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'USER_ACCOUNT'}->{'STATUS'} == 50 ? "Active" : "Inactive"),
    subject   => "Status"
  );

  $Body .= $Dialog->TextBox(
    value     => $GENERAL->{'USER_LEVELS'}->{ $in{'input'}->{'USER_ACCOUNT'}->{'LEVEL'} },
    subject   => "Level"
  );

  $Body .= $Dialog->Button(buttons => [{ type => "submit", value => "Modify" }]);
  $Page .= $Dialog->Dialog(body => $Body, colspan => 4);
  
  $Page .= $Dialog->SmallHeader(
    titles => [
      { text => "", width => 1, nowrap => 1 },
      { text => "", width => "100%" },
      { text => "", width => 200, nowrap => 1 },
      { text => "", width => 200, nowrap => 1 }
    ]
  );

  $Page .= $Dialog->LargeHeader(title => "Tickets", colspan => 4);
  
  foreach my $ticket (@{ $in{'input'}->{'TICKETS'} }) {
    my @fields;
    $fields[0] = $ticket->{'ID'};
    
    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=ViewModifyTicket&TID=$ticket->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $ticket->{'SUBJECT'};
    $fields[1] .= qq~</a>~;
    
    $fields[2] = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$ticket->{'CATEGORY'}}]->{'NAME'};
    $fields[3] = $ticket->{'CREATE_DATE'}." at ".$ticket->{'CREATE_TIME'};
    
    $Page .= $Dialog->Row(fields => \@fields);
  }

  if (scalar(@{ $in{'input'}->{'TICKETS'} }) < 1) {
    $Page .= $Dialog->Row(fields => "This user hasn't posted any tickets.", colspan => 5);
  }

  $Page = $Dialog->Body($Page);
  $Page = $Dialog->Form(
    body    => $Page,
    hiddens => [
      { name => "USERNAME", value => $in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'} },
      { name => "CP", value => "1" },
      { name => "action", value => "ViewModifyUser" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Page = $Dialog->Page(body => $Page);
  
  return $Page;
}

1;