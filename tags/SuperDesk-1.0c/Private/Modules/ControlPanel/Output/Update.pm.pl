###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Update.pm.pl -> Update skin module                       #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Update;

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
  my %in = (input => undef, error => "", @_);

  my $LANGUAGE = {
    "MISSING" => {
      "SERVER"        => qq~<li>You didn't fill in the "Update Server" field.~,
      "USERNAME"      => qq~<li>You didn't fill in the "Registration Username" field.~,
      "PASSWORD"      => qq~<li>You didn't fill in the "Registration Password" field.~
    },
    "INVALID" => {
      "LOGIN"         => qq~<li>The Username and Password you entered are invalid.~
    },
    "CONN-ERROR"    => qq~<li>There was an error connecting to the Update Server.~,
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "To view the list of updates, first enter the following information:".$in{'error'});

  $Body .= $Dialog->TextBox(
    name      => "FORM_SERVER",
    value     => $SD::QUERY{'FORM_SERVER'} || "update.plasmapulse.com",
    subject   => "Update Server",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_USERNAME",
    value     => $SD::QUERY{'FORM_USERNAME'},
    subject   => "Registration Username",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_PASSWORD",
    value     => $SD::QUERY{'FORM_PASSWORD'},
    subject   => "Registration Password",
    required  => 1
  );

  $Body .= $Dialog->Button(
    buttons  => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "update superlinks").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "ViewUpdate" },
      { name => "CP", value => "1" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "Select a version to update to:");
  
  my $value = qq~<table cellpadding="2" cellspacing="0" width="100%">~;
  
  foreach my $version (@{ $in{'input'}->{'VERSIONS'} }) {
    $value .= qq~<tr>~;
    $value .= qq~<td width="1" valign="top" nowrap><input type="radio" name="FORM_VERSION" value="$version->{'VERSION'}"></td>~;
    $value .= qq~<td width="100%" valign="top"><font class="textbox"><b>$version->{'DESCRIPTION'}</b></font></td>~;
    $value .= qq~</tr>~;
  }
  
  $value .= qq~</table>~;

  $Body .= $Dialog->Text(text => $value);  

  $Body .= $Dialog->Button(
    buttons  => [
      { type => "submit", value => "Update" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "update superlinks").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "FORM_SERVER", value => $SD::QUERY{'FORM_SERVER'} },
      { name => "FORM_USERNAME", value => $SD::QUERY{'FORM_USERNAME'} },
      { name => "FORM_PASSWORD", value => $SD::QUERY{'FORM_PASSWORD'} },
      { name => "action", value => "DoUpdate" },
      { name => "CP", value => "1" },
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
  my ($section) = @_;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body;
  if ($section eq "header") {
    require "Skins/$SD::GLOBAL{'SKIN'}/StyleSheet.pm.pl";
    my $STYLE = StyleSheet->new();

    $Body = $Dialog->Text(text => "Updating:");

    my $value  = qq~<iframe src="#" name="LOG" height="300" width="100%"></iframe>~;
       $value .= <<HTML;
<script language="JavaScript">
  <!--
  document.LOG.document.open();
  document.LOG.document.write("<html>\\n<head>\\n<title>Log</title>\\n<link type=\\"text/css\\" href=\\"$SYSTEM->{'SCRIPT_URL'}?action=StyleSheet\\" rel=\\"stylesheet\\">\\n</head>\\n<body style=\\"background-color: $STYLE->{'TBODY_BGCOLOR'}\\">\\n<font class=\\"normal\\">\\n");
  //-->
</script>
HTML

    $Body .= $Dialog->Text(text => $value);
    $Body .= $Dialog->Button(
      buttons  => [
        { type => "button", value => "Close", extra => "onClick=\"window.location='$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UnresolvedTickets&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}'\"" },
      ]
    );

    $Body = $Dialog->Dialog(body => $Body);
    $Body = $Dialog->SmallHeader(titles => "update superlinks").$Body;
  
    $Body = $Dialog->Body($Body);
    $Body = $Dialog->Page(body => $Body, section => "header");
  } else {
    $Body = <<HTML;
<script language="JavaScript">
  <!--
  document.LOG.document.close();
  //-->
</script>
HTML

    $Body = $Dialog->Page(body => $Body, section => "footer");
  }

  return $Body;
}

1;