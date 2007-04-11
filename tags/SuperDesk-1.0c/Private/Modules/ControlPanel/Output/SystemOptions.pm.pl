###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/SystemOptions.pm.pl -> SystemOptions skin module         #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::SystemOptions;

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
  my %in = (error => "", @_);

  my @Sections = (
    { title => "Paths", items => [
      { subject => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:", type => "text" },
      { name => "DB_PATH", subject => "Database Path", type => "textbox", required => 1, iconhelp => "The full UNIX-style path to the Database directory." },
      { name => "TEMP_PATH", subject => "Temporary Path", type => "textbox", required => 1, iconhelp => "The full UNIX-style path to the Temp directory." },
      { name => "LOGS_PATH", subject => "Logs Path", type => "textbox", required => 1, iconhelp => "The full UNIX-style path to the Logs directory." },
      { name => "BACKUP_PATH", subject => "Backup Path", type => "textbox", required => 1, iconhelp => "The full UNIX-style path to the Backups directory." },
      { name => "PUBLIC_PATH", subject => "Public Path", type => "textbox", required => 1, iconhelp => "The full UNIX-style path to the Public directory." },
      { name => "CACHE_PATH", subject => "Template Cache Path", type => "textbox", required => 1, iconhelp => "The full UNIX-style path to the template Cache directory." }
    ]},
    { title => "URLs", items => [
      { name => "SCRIPT_URL", subject => "Script URL", type => "textbox", required => 1, iconhelp => "The full URL of the main SuperDesk script." },
      { name => "PUBLIC_URL", subject => "Public URL", type => "textbox", required => 1, iconhelp => "The full URL to the Public directory." }
    ]},
    { title => "Database Engine", items => [
      { name => "DB_TYPE", subject => "Database System", type => "textbox", locked => 1 },
      { name => "DB_PREFIX", subject => "Table Prefix", type => "textbox", locked => 1 },
      { name => "DB_HOST", subject => ($SYSTEM->{'DB_TYPE'} eq "oracle" ? "Oracle Home Path (ORACLE_HOME)" : "SQL Server Host/Address"), type => "textbox" },
      { name => "DB_PORT", subject => ($SYSTEM->{'DB_TYPE'} eq "port" ? "TNS Admin Path (TNS_ADMIN)" : "SQL Server Port"), type => "textbox" },
      { name => "DB_NAME", subject => "SQL Database Name", type => "textbox" },
      { name => "DB_USERNAME", subject => "SQL Database Username", type => "textbox" },
      { name => "DB_PASSWORD", subject => "SQL Database Password", type => "textbox" }
    ]},
    { title => "Mail Options", items => [
      { name => "MAIL_TYPE", subject => "Mail System", type => "radio(SENDMAIL[Sendmail],SMTP[SMTP])", required => 1, iconhelp => "The type of email system to use." },
      { name => "SENDMAIL", subject => "Sendmail Path", type => "textbox", iconhelp => "The full UNIX-style path to Sendmail or the equivalent on your server." },
      { name => "SMTP_SERVER", subject => "SMTP Server", type => "textbox", iconhelp => "The hostname of a SMTP server accessible to this web server." }
    ]},
    { title => "Misc. Options", items => [
      { name => "FLOCK", subject => "File Locking", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable file locking. This should only be attempted on a *NIX system, not a Windows one." },
      { name => "LOG_ERRORS", subject => "Error Logging", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Log errors for viewing later." },
      { name => "SHOW_CGI_ERRORS", subject => "Detailed CGI Errors", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Show detailed CGI errors with paths, variable values, etc. Not recommended on public systems." },
      { name => "CACHING", subject => "Template Caching", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable template caching. When enabled, templates will be built as Perl modules for faster execution." },
      { name => "START_TAG", subject => "Template Start Tag", type => "textbox", required => 1, iconhelp => "The character(s) used to start a template tag." },
      { name => "END_TAG", subject => "Template End Tag", type => "textbox", required => 1, iconhelp => "The character(s) used to end a template tag." },
      { name => "LOCALTIME_OFFSET", subject => "Server Time Offset", type => "textbox", iconhelp => "The number of hours to offset the server's time to bring it in line with your local time. For example, if the server is five hours behind your local time, then enter +5 in this field." },
      { type => "buttons" }
    ]},
  );

  my $LANGUAGE = {
    "MISSING" => { },
    "ERROR"   => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };
  
  foreach my $section (@Sections) {
    foreach my $item (@{ $section->{'items'} }) {
      $LANGUAGE->{'MISSING'}->{ $item->{'name'} } = qq~<li>You didn't fill in the "$item->{'subject'}" field.~ if ($item->{'subject'});
    }
  }
  
  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});
  $Sections[0]->{'items'}->[0]->{'subject'} .= $in{'error'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->SmallHeader(titles => "system options");
  
  foreach my $section (@Sections) {
    $Body .= $Dialog->LargeHeader(title => $section->{'title'}) if ($section->{'title'});
    
    my $Temp;
    foreach my $item (@{ $section->{'items'} }) {
      if ($item->{'type'} eq "textbox") {
        $Temp .= $Dialog->TextBox(
          name      => ($item->{'locked'} ? "" : "FORM_".$item->{'name'}),
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $SYSTEM->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} =~ /^radio\((.*)\)$/) {
        my $radios = $1;
        my @radios = split(/,/, $radios);
        foreach my $radio (@radios) {
          $radio =~ m/^(.*)\[(.*)\]$/;
          $radio = { value => $1, label => $2 };
        }
        $Temp .= $Dialog->Radio(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $SYSTEM->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          radios    => \@radios,
          join      => "&nbsp;",
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} =~ /^vertradio\((.*)\)$/) {
        my $radios = $1;
        my @radios = split(/,/, $radios);
        foreach my $radio (@radios) {
          $radio =~ m/^(.*)\[(.*)\]$/;
          $radio = { value => $1, label => $2 };
        }
        $Temp .= $Dialog->Radio(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $SYSTEM->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          radios    => \@radios,
          join      => "<br>",
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} eq "text") {
        $Temp .= $Dialog->Text(text => $item->{'subject'});
      } elsif ($item->{'type'} eq "buttons") {
        $Temp .= $Dialog->Button(
          buttons => [
            { type => "submit", value => "Modify" },
            { type => "reset", value => "Cancel" }
          ], join => "&nbsp;"
        );
      }
    }
    
    $Body .= $Dialog->Dialog(body => $Temp);
  }
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "DoSystemOptions" },
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

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The system options have been updated.");
     $Body = $Dialog->Dialog(body => $Body);
  
     $Body = $Dialog->SmallHeader(titles => "system options").$Body;
     
     $Body = $Dialog->Body($Body);
     $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;