###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/RemoveUsers.pm.pl -> RemoveUsers skin module             #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::RemoveUsers;

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
      { text => "", width => 1 },
      { text => "name", width => "100%" },
      { text => "username", width => 250, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Remove Users", colspan => 3);
  
  foreach my $user (@{ $in{'input'}->{'USER_ACCOUNTS'} }) {
    my @fields;
    $fields[0] = $Form->CheckBox(
      checkboxes  => [
        { name => "USERNAME", value => $user->{'USERNAME'} }
      ]
    );

    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$user->{'USERNAME'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $user->{'NAME'};
    $fields[1] .= qq~</a>~;

    $fields[2] = $user->{'USERNAME'};
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "button", value => "Select All", extra => "onClick=\"checkAll()\"" },
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 3);

  my $Script  = qq~<script language="JavaScript">\n~;
     $Script .= qq~  <!--\n~;
     $Script .= qq~  function checkAll() {\n~;
  
  if (scalar(@{ $in{'input'}->{'USER_ACCOUNTS'} }) == 1) {
    $Script .= qq~    document.form.USERNAME.checked = true;\n~;
  } elsif (scalar(@{ $in{'input'}->{'USER_ACCOUNTS'} }) > 1) {
    $Script .= qq~    for (var h = 0; h <= ~.(scalar(@{ $in{'input'}->{'USER_ACCOUNTS'} }) - 1).qq~; h++) {\n~;
    $Script .= qq~      document.form.USERNAME[h].checked = true;\n~;
    $Script .= qq~    }\n~;
  }
  
  $Script .= qq~  }\n~;
  $Script .= qq~  //-->\n~;
  $Script .= qq~</script>\n~;

  $Body = $Script.$Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "DoRemoveUsers" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The selected users have been removed.");

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "remove users").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;