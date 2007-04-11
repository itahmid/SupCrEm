###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Error.pm.pl -> Error library                                                #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Error;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use strict;

###############################################################################
# Error subroutine
sub Error {
  my $Platform = shift;
  my %in = (MESSAGE => "", @_);

  if ($SYSTEM->{'LOG_ERRORS'} == 1) {
    open (ERROR_LOG, ">>$SYSTEM->{'LOGS_PATH'}/error.log.txt");
    print ERROR_LOG "$Platform|^|400|^|$in{'MESSAGE'}|^||^|$ENV{'REMOTE_ADDR'}|^|".time."\n";
    close (ERROR_LOG);
    chmod (0777, "$SYSTEM->{'LOGS_PATH'}/error.log.txt");
  }

  &Standard::PrintHTMLHeader();

  if ($Platform eq "SD") {
    require "Skins/$SD::GLOBAL{'SKIN'}/Modules/Error.pm.pl";

    my $Skin = Skin::Error->new();
    print $Skin->show(error => $in{'MESSAGE'});
  } elsif ($Platform eq "CP") {
    require "ControlPanel/Output/Error.pm.pl";

    my $Skin = Skin::CP::Error->new();
    print $Skin->show(error => $in{'MESSAGE'});
  }
  
  exit;
}

###############################################################################
# CGIError subroutine
sub CGIError {
  my ($message, $path) = @_;

  my ($key, $space);

  &Standard::PrintHTMLHeader();
  
  $message =~ s/\n/<br>/g;

  if ($SYSTEM->{'LOG_ERRORS'} == 1) {
    open (ERROR_LOG, ">>$SYSTEM->{'LOGS_PATH'}/error.log.txt");
    print ERROR_LOG "|^|500|^|$message|^|$path|^|$ENV{'REMOTE_ADDR'}|^|".time."\n";
    close (ERROR_LOG);
    chmod (0777, "$SYSTEM->{'LOGS_PATH'}/error.log.txt");
  }
  
  print "<html>\n";
  print "<head>\n";
  print "<title>CGI Script Error</title>\n";
  print "</head>\n";
  print "<body marginheight=\"5\" marginwidth=\"5\" leftmargin=\"5\" topmargin=\"5\" rightmargin=\"5\">\n";
  print "<font face=\"Verdana\">\n";
  print "<font size=\"4\"><b>CGI Script Error</b></font><p>\n";
  print "<font size=\"2\">\n";

  # printing error message
  if ($message) {
    print $message;
  }
  
  if ($SYSTEM->{'SHOW_CGI_ERRORS'}) {
    print "<p>";

    # printing general infomation
    print "<font size=\"4\"><b>General Infomation</b></font><p>\n";
    print "<table cellpadding=\"0\" cellspacing=\"0\">\n";

    if ($path) {
      $path =~ s/\\/\//g;
      print "<tr>\n";
      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>Error Path</b></font></td>\n";
      print "<td><font face=\"Verdana\" size=\"2\">$path</font></td>\n";
      print "</tr>\n";
    }
    if ($0) {
      $0 =~ s/\\/\//g;
      print "<tr>\n";
      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>Script Path</b></font></td>\n";
      print "<td><font face=\"Verdana\" size=\"2\">$0</font></td>\n";
      print "</tr>\n";
    }
    if ($]) {
      print "<tr>\n";
      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>Perl Version</b></font></td>\n";
      print "<td><font face=\"Verdana\" size=\"2\">$]</font></td>\n";
      print "</tr>\n";
    }
    if ($SD::VERSION) {
      print "<tr>\n";
      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>SuperDesk Version</b></font></td>\n";
      print "<td><font face=\"Verdana\" size=\"2\">$SD::VERSION</font></td>\n";
      print "</tr>\n";
    }
    if ($CGI::VERSION) {
      print "<tr>\n";
      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>CGI.pm Version</b></font></td>\n";
      print "<td><font face=\"Verdana\" size=\"2\">$CGI::VERSION</font></td>\n";
      print "</tr>\n";
    }
    print "</table><p>\n";

    if (defined %SD::QUERY) {
      # printing form variables
      print "<font size=\"4\"><b>Form Variables</b></font><p>\n";
      print "<table cellpadding=\"0\" cellspacing=\"0\">\n";
      foreach my $KEY (sort keys %SD::QUERY) {
        print "<tr>\n";
        print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>$KEY</b></font></td>\n";
        print "<td><font face=\"Verdana\" size=\"2\">".$SD::QUERY{$KEY}."</font></td>\n";
        print "</tr>\n";
      }
      print "</table><p>\n";
    }

    # printing environment variables
    print "<font size=\"4\"><b>Environment Variables</b></font><p>\n";
    print "<table cellpadding=\"0\" cellspacing=\"0\">\n";
    foreach $key (sort keys %ENV) {
      print "<tr>\n";
      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>$key</b></font></td>\n";
      print "<td><font face=\"Verdana\" size=\"2\">".$ENV{$key}."</font></td>\n";
      print "</tr>\n";
    }
    print "</table><p>\n";

    # printing @INC
    print "<font size=\"4\"><b>\@INC Contents</b></font><p>\n";
    print "<ul>\n";
    foreach $INC (@INC) {
      print "<li>$INC<br>\n";
    }
    print "</ul><p>\n";
  }
  
  print "</font>\n";
  print "</font>\n";
  print "</body>\n";
  print "</html>\n";

  exit;
}

1;