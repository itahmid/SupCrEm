###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Restore.pm.pl -> Restore skin module                     #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Restore;

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

  my $Body = $Dialog->Text(text => "Select a backup to restore:");
  
  my $value = qq~<table cellpadding="2" cellspacing="0" width="100%">~;
  
  foreach my $backup (@{ $in{'input'}->{'BACKUPS'} }) {
    $value .= qq~<tr>~;
    $value .= qq~<td width="1" valign="top" nowrap><input type="radio" name="FORM_BACKUP" value="SD-$backup->{'SECOND'}"></td>~;
    $value .= qq~<td width="100%" valign="top"><font class="textbox"><b>$backup->{'TIME'} on $backup->{'DATE'}</b>~;
    $value .= qq~ <small>(<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=ViewBackupLog&BACKUP=SD-$backup->{'SECOND'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">view log</a> |~;
    $value .= qq~ <a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=DoRemoveBackup&BACKUP=SD-$backup->{'SECOND'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">remove</a>)</small><br>~;
    $value .= qq~$backup->{'DESCRIPTION'}</font></td>~;
    $value .= qq~</tr>~;
  }

  $value .= qq~<tr>~;
  $value .= qq~<td width="1" valign="top" nowrap><input type="checkbox" name="FORM_RESTORE_SKINS" value="1"></td>~;
  $value .= qq~<td width="100%" valign="top"><font class="label">Restore skins if available?</font></td>~;
  $value .= qq~</tr>~;
  $value .= qq~<tr>~;
  $value .= qq~<td width="1" valign="top" nowrap><input type="checkbox" name="FORM_RESTORE_ATTACHMENTS" value="1" checked></td>~;
  $value .= qq~<td width="100%" valign="top"><font class="label">Restore attachments if available?</font></td>~;
  $value .= qq~</tr>~;
  $value .= qq~</table>~;

  $Body .= $Dialog->Text(text => $value);  

  $Body .= $Dialog->Button(
    buttons  => [
      { type => "submit", value => "Restore" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "restore database").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "DoRestore" },
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

    $Body = $Dialog->Text(text => "Restoring database:");

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
    $Body = $Dialog->SmallHeader(titles => "restore database").$Body;
  
    $Body = $Dialog->Body($Body);
    $Body = $Dialog->Page(body => $Body, header => "header");
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