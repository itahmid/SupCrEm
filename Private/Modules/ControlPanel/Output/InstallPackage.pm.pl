###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/InstallPackage.pm.pl -> InstallPackage skin module       #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::InstallPackage;

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
  my %in = (error => "", @_);

  my $LANGUAGE = {
    "MISSING" => {
      "PACKAGE" => qq~<li>You didn't fill in the "Package" field.~
    },
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body  = $Dialog->Text(text => "<font color=\"Red\">Never install a package from an unverified source and always be careful when using packages that aren't directly from Obsidian-Scripts.</font>".$in{'error'});

  my $value = qq~<input type="file" name="FORM_PACKAGE" value="$SD::QUERY{'FORM_PACKAGE'}" class="textbox">~;
  $Body .= $Dialog->TextBox(
    value     => $value,
    subject   => "Package",
    required  => 1
  );

  $Body .= $Dialog->Button(
    buttons  => [
      { type => "submit", value => "Install" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "install package").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "DoInstallPackage" },
      { name => "CP", value => "1" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ],
    extra => "enctype=\"multipart/form-data\""
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

    $Body = $Dialog->Text(text => "Installing Package:");

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
    $Body = $Dialog->SmallHeader(titles => "install package").$Body;
  
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