###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Backup.pm.pl -> Backup skin module                       #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Backup;

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

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body  = $Dialog->Text(text => "From here you can backup the SuperLinks database:");

  $Body .= $Dialog->TextArea(
    name     => "FORM_DESCRIPTION",
    value    => $SD::QUERY{'FORM_DESCRIPTION'},
    subject  => "Description",
    rows     => 3
   );

  $Body .= $Dialog->CheckBox(
    name       => "FORM_BACKUP_SKINS",
    value      => $SD::QUERY{'FORM_BACKUP_SKINS'},
    checkboxes => [{ value => "1", label => "Backup skins." }]
  );

  $Body .= $Dialog->CheckBox(
    name       => "FORM_BACKUP_ATTACHMENTS",
    value      => $SD::QUERY{'FORM_BACKUP_ATTACHMENTS'} || "1",
    checkboxes => [{ value => "1", label => "Backup attachments." }]
  );

  $Body .= $Dialog->CheckBox(
    name       => "FORM_COMPRESS",
    value      => $SD::QUERY{'FORM_COMPRESS'},
    checkboxes => [{ value => "1", label => "Pack the backup into a .tar or .tar.gz archive." }]
   );

   $Body .= $Dialog->Button(
     buttons  => [
       { type => "submit", value => "Backup" },
       { type => "reset", value => "Cancel" }
     ], join => "&nbsp;"
   );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "backup database").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "DoBackup" },
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

    $Body = $Dialog->Text(text => "Backing up database:");

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
    $Body = $Dialog->SmallHeader(titles => "backup database").$Body;

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