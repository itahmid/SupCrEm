###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/ConvertDatabase.pm.pl -> ConvertDatabase skin module     #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::ConvertDatabase;

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

  my $Body = $Dialog->Text(text => "Select a database type to convert:");
  
  my $value = qq~<table cellpadding="2" cellspacing="0" width="100%">~;
  
  foreach my $database (@{ $in{'input'}->{'DATABASES'} }) {
    $value .= qq~<tr>~;
    $value .= qq~<td width="1" valign="top" nowrap><input type="radio" name="FORM_DATABASE" value="$database->{'NAME'}"></td>~;
    $value .= qq~<td width="100%" valign="top"><font class="textbox">$database->{'DESCRIPTION'}</font></td>~;
    $value .= qq~</tr>~;
  }
  
  $value .= qq~</table>~;

  $Body .= $Dialog->Text(text => $value);  

  $Body .= $Dialog->Button(
    buttons  => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "convert database").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "ViewConvertDatabase" },
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
  my %in = (input => undef, error => "", @_);

  if ($in{'error'}) {
    my @errors = @{ $in{'error'} };
    $in{'error'} = qq~<p><font class="error-body">There were errors:<ul>~;
    foreach my $error (@errors) {
      $in{'error'} .= "<li>$error";
    }
    $in{'error'} .= qq~</ul></font>~;
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "Database: <b>$in{'input'}->{'DATABASE'}->{'DESCRIPTION'}</b><br>Please fill out all the required (<font color=\"Red\">*</font>) fields:".$in{'error'});
  
  foreach my $field (@{ $in{'input'}->{'FIELDS'} }) {
    if ($field->{'type'} eq "textbox") {
      $Body .= $Dialog->TextBox(%{ $field }, name => "FORM_".$field->{'name'}, value => $SD::QUERY{'FORM_'.$field->{'name'}});
    } elsif ($field->{'type'} eq "checkbox") {
      $Body .= $Dialog->CheckBox(%{ $field }, name => "FORM_".$field->{'name'}, value => $SD::QUERY{'FORM_'.$field->{'name'}});
    } elsif ($field->{'type'} eq "radio") {
      $Body .= $Dialog->Radio(%{ $field }, name => "FORM_".$field->{'name'}, value => $SD::QUERY{'FORM_'.$field->{'name'}});
    } elsif ($field->{'type'} eq "textarea") {
      $Body .= $Dialog->TextArea(%{ $field }, name => "FORM_".$field->{'name'}, value => $SD::QUERY{'FORM_'.$field->{'name'}});
    }
  }

  $Body .= $Dialog->Button(
    buttons  => [
      { type => "submit", value => "Convert" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "convert database").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "FORM_DATABASE", value => $in{'input'}->{'DATABASE'}->{'NAME'} },
      { name => "action", value => "DoConvertDatabase" },
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

    $Body = $Dialog->Text(text => "Converting database:");

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
    $Body = $Dialog->SmallHeader(titles => "convert database").$Body;
  
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