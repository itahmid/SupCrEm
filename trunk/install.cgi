#!/usr/bin/perl
#^^^^^^^^^^^^^^ Change this to the location of Perl                           #
###############################################################################
# SuperDesk                                                                   #
# Copyright (c) 2002-2007 Greg Nolle (http://greg.nolle.co.uk)                #
###############################################################################
# This program is free software; you can redistribute it and/or modify it     #
# under the terms of the GNU General Public License as published by the Free  #
# Software Foundation; either version 2 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# This program is distributed in the hope that it will be useful, but WITHOUT #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       #
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for   #
# more details.                                                               ##                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with this program; if not, write to the Free Software Foundation, Inc.,     #
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.                 #
###############################################################################
# install.cgi -> Install script                                               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package SD;

BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File SDBM_File) }

BEGIN {
  #############################################################################
  # Change this to the path to this script if it fails.                       #
  $SD::PATH = "."; # < < < < < < < < < < < < < < < < < < < < < < < < < < < < <#
  #############################################################################
  # DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                       #
  #############################################################################

  $SD::EXTENSION = $0;
  $SD::EXTENSION =~s/\\/\//g;
  $SD::EXTENSION =~s/^.*\.(\w+)$/$1/g;

  foreach my $path ( $ENV{'SCRIPT_FILENAME'}, $ENV{'PATH_TRANSDATED'}, $0 ) {
    $path =~s/\\/\//g;
    $path =~s/^(.*)\/[^\/]+$/$1/g;
    if (-e $path."/install.".$SD::EXTENSION) {
      $SD::PATH = $path;
      last;
    }
  }

  unshift (@INC, "$SD::PATH");
  %SD::GLOBAL = ("SKIN" => "Default");
}

eval { require 5.005; } || &CGIError("Can't load Perl version 5.005 or higher. $@", "");

use CGI;
use Cwd;
use File::Path;

use strict;

###############################################################################
# Main script: #
################

$| = 1;

eval { require Archive::Tar; } || &CGIError("Can't require Archive::Tar module. $@. Please check that it is uploaded into this directory.", "");

$SD::CGI = CGI->new();

foreach my $keyword ($SD::CGI->param()) {
  $SD::QUERY{ $keyword } = $SD::CGI->param( $keyword );
}

print "Content-Type: text/html\n\n";
$SD::HTML_HEADER = 1;

eval { &Main; } || &CGIError("Couldn't execute your request. $@.", "");
exit;

###############################################################################
# Main subroutine
sub Main {
  if ($SD::QUERY{'action'} eq "DoInstall") {
    &DoInstall() and return 1;
  } elsif ($SD::QUERY{'action'} eq "CreateTables") {
    &CreateTables() and return 1;
  } else {
    &Install() and return 1;
  }
}

###############################################################################
# Install subroutine
sub Install {
  my %in = (ERROR => "", @_);

  my %FORM;
  
  $FORM{'PATH'}         = $SD::QUERY{'FORM_PATH'} || $SD::PATH;
  $FORM{'PUBLIC_PATH'}  = $SD::QUERY{'FORM_PUBLIC_PATH'} || "$FORM{'PATH'}/Public";

  my $http = "http://";
     $http = "https://" if ($ENV{'CHARSET_HTTP_METHOD'} eq "https://");
  $FORM{'URL'} = $http.$ENV{'HTTP_HOST'}.$ENV{'SCRIPT_NAME'};
  $FORM{'URL'} =~ s/\/install\.$SD::EXTENSION$//;
  $FORM{'URL'} ||= $SD::QUERY{'FORM_URL'};
  $FORM{'PUBLIC_URL'} = $SD::QUERY{'FORM_PUBLIC_URL'} || "$FORM{'URL'}/Public";
  
  $FORM{'MYSQL_SERVER'}     = $SD::QUERY{'FORM_MYSQL_SERVER'} || "localhost";
  $FORM{'MYSQL_PORT'}       = $SD::QUERY{'FORM_MYSQL_PORT'} || "3306";
  $FORM{'MYSQL_DB_NAME'}    = $SD::QUERY{'FORM_MYSQL_DB_NAME'} || "superdesk";
  $FORM{'MYSQL_USERNAME'}   = $SD::QUERY{'FORM_MYSQL_USERNAME'};
  $FORM{'MYSQL_PASSWORD'}   = $SD::QUERY{'FORM_MYSQL_PASSWORD'};
  $FORM{'MYSQL_PREFIX'}     = $SD::QUERY{'FORM_MYSQL_PREFIX'} || "SD_";
  
  $FORM{'MSSQL_DB_NAME'}    = $SD::QUERY{'FORM_MSSQL_DB_NAME'} || "superdesk";
  $FORM{'MSSQL_USERNAME'}   = $SD::QUERY{'FORM_MSSQL_USERNAME'};
  $FORM{'MSSQL_PASSWORD'}   = $SD::QUERY{'FORM_MSSQL_PASSWORD'};
  $FORM{'MSSQL_PREFIX'}     = $SD::QUERY{'FORM_MSSQL_PREFIX'} || "SD_";
  
  $FORM{'ORACLE_SERVER'}    = $SD::QUERY{'FORM_ORACLE_SERVER'} || "/dev/null";
  $FORM{'ORACLE_PORT'}      = $SD::QUERY{'FORM_ORACLE_PORT'} || "/var/opt/oracle";
  $FORM{'ORACLE_DB_NAME'}   = $SD::QUERY{'FORM_ORACLE_DB_NAME'} || "superdesk";
  $FORM{'ORACLE_USERNAME'}  = $SD::QUERY{'FORM_ORACLE_USERNAME'};
  $FORM{'ORACLE_PASSWORD'}  = $SD::QUERY{'FORM_ORACLE_PASSWORD'};
  $FORM{'ORACLE_PREFIX'}    = $SD::QUERY{'FORM_ORACLE_PREFIX'} || "SD_";

  if ($SD::QUERY{'FORM_DB_TYPE'} eq "mysql") {
    $FORM{'MYSQL_CHECKED'} = "checked";
  } elsif ($SD::QUERY{'FORM_DB_TYPE'} eq "mssql") {
    $FORM{'MSSQL_CHECKED'} = "checked";
  } elsif ($SD::QUERY{'FORM_DB_TYPE'} eq "oracle") {
    $FORM{'ORACLE_CHECKED'} = "checked";
  } else {
    $FORM{'DBM_CHECKED'} = "checked";
  }

  foreach my $path ("/usr/sbin/sendmail", "/usr/lib/sendmail", "/usr/bin/sendmail", "/var/qmail/bin/qmail-inject") {
    $FORM{'SENDMAIL'} = $path if (-e $path);
  }
  $FORM{'SENDMAIL'} = $SD::QUERY{'FORM_SENDMAIL'} || $FORM{'SENDMAIL'};

  if ($SD::QUERY{'FORM_SENDMAIL'} || $SD::QUERY{'FORM_MAIL_TYPE'} eq "SENDMAIL") {
    $FORM{'SENDMAIL_CHECKED'} = "checked";
  } elsif ($SD::QUERY{'FORM_SMTP'} || $SD::QUERY{'FORM_MAIL_TYPE'} eq "SMTP") {
    $FORM{'SMTP_CHECKED'} = "checked";
  } elsif ($FORM{'SENDMAIL'}) {
    $FORM{'SENDMAIL_CHECKED'} = "checked";
  } else {
    $FORM{'SMTP_CHECKED'} = "checked";
  }

  $FORM{'SMTP_SERVER'}      = $SD::QUERY{'FORM_SMTP_SERVER'} || "localhost";
  $FORM{'EMAIL'}            = $SD::QUERY{'FORM_EMAIL'} || $ENV{'SERVER_ADMIN'};
  $FORM{'LOCALTIME_OFFSET'} = $SD::QUERY{'FORM_LOCALTIME_OFFSET'} || "0";

  $FORM{'ADMIN_USERNAME'}   = $SD::QUERY{'FORM_ADMIN_USERNAME'};
  $FORM{'ADMIN_PASSWORD'}   = $SD::QUERY{'FORM_ADMIN_PASSWORD'};
  $FORM{'ADMIN_NAME'}       = $SD::QUERY{'FORM_ADMIN_NAME'};

  if ($in{'ERROR'}) {
    $in{'ERROR'} = qq~<br><font color="Red">There were errors:<ul>$in{'ERROR'}</ul></font>~;
  }

  print <<HTML;
<html>

<head>
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<meta name="GENERATOR" content="Microsoft FrontPage 4.0">
<meta name="ProgId" content="FrontPage.Editor.Document">
<title>SuperDesk Installation</title>
<style>
<!--
a            { text-decoration: none }
a:hover      { text-decoration: underline }
-->
</style>
</head>

<body topmargin="5" leftmargin="5" marginheight="5" marginwidth="5" text="#333333" link="#3366CC" vlink="#3366CC" alink="#3366CC">

<table border="0" cellpadding="0" cellspacing="1" width="100%" bgcolor="#333333"><form method="POST" action="$FORM{'URL'}/install.$SD::EXTENSION">
  <tr>
    <td width="100%" bgcolor="#FFFFFF">
      <table border="0" cellpadding="4" cellspacing="1" width="100%" bgcolor="#333333">
        <tr>
          <td width="100%"><font face="Verdana" size="1" color="#FFFFFF"><b>superdesk installation</b></font></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><b><font face="Verdana" size="2">Paths</font></b></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <table border="0" cellpadding="2" cellspacing="0" width="100%">
              <tr>
                <td width="100%" valign="top" colspan="2"><font face="Verdana" size="2">Please fill out all the required
                  (<font color="#FF0000" size="2" face="Verdana"><b>*</b></font>) fields:<br>
                  $in{'ERROR'}</font></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Path </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top" nowrap><input type="text" name="FORM_PATH" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'PATH'}"><br>
                  <font face="Verdana" size="1">Full UNIX-style path to
                  the directory containing the install.cgi script.</font></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Public Path </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top" nowrap><input type="text" name="FORM_PUBLIC_PATH" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'PUBLIC_PATH'}"><br>
                  <font face="Verdana" size="1">Full UNIX-style path to
                  the Public directory.</font></td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><b><font face="Verdana" size="2">URLs</font></b></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <table border="0" cellpadding="2" cellspacing="0" width="100%">
              <tr>
                <td width="200" nowrap valign="top"><b><font face="Verdana" size="2">URL </font></b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_URL" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'URL'}"><br>
                  <font face="Verdana" size="1">Full URL to the directory
                  containing the install.cgi script.</font></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><b><font face="Verdana" size="2">Public URL </font></b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_PUBLIC_URL" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'PUBLIC_URL'}"><br>
                  <font face="Verdana" size="1">Full URL to the Public directory.</font></td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><font face="Verdana" size="2"><b>Database Engine</b></font></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <table border="0" cellpadding="2" cellspacing="0" width="100%">
              <tr>
                <td width="200" valign="top" nowrap><b><font face="Verdana" size="2">Database Type </font></b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></td>
                <td width="100%">
                  <table border="0" cellpadding="2" cellspacing="0" width="100%">
                    <tr>
                      <td width="1" nowrap><input type="radio" name="FORM_DB_TYPE" value="dbm" $FORM{'DBM_CHECKED'}></td>
                      <td width="100%" nowrap colspan="3"><font face="Verdana" size="2">Use
                        DBM (DB, GDBM, NDBM, or SDBM)</font></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap><input type="radio" name="FORM_DB_TYPE" value="mysql" $FORM{'MYSQL_CHECKED'}></td>
                      <td width="100%" nowrap colspan="3"><font face="Verdana" size="2">Use
                        MySQL (requires that <i>DBI</i> and <i>DBD::MySQL</i> are installed)</font></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><font size="2" face="Verdana"><b>Server</b></font></td>
                      <td width="100%"><input type="text" name="FORM_MYSQL_SERVER" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MYSQL_SERVER'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><font size="2" face="Verdana"><b>Port</b></font></td>
                      <td width="100%"><input type="text" name="FORM_MYSQL_PORT" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MYSQL_PORT'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Database
                        Name</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MYSQL_DB_NAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MYSQL_DB_NAME'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Username</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MYSQL_USERNAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MYSQL_USERNAME'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Password</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MYSQL_PASSWORD" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MYSQL_PASSWORD'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Table Prefix</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MYSQL_PREFIX" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MYSQL_PREFIX'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap><input type="radio" name="FORM_DB_TYPE" value="mssql" $FORM{'MSSQL_CHECKED'}></td>
                      <td width="100%" nowrap colspan="3"><font face="Verdana" size="2">Use
                        Microsoft SQL Server (requires that <i>Win32::ODBC</i> is installed)</font></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Database
                        Name</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MSSQL_DB_NAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MSSQL_DB_NAME'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Username</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MSSQL_USERNAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MSSQL_USERNAME'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Password</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MSSQL_PASSWORD" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MSSQL_PASSWORD'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Table Prefix</font></b></td>
                      <td width="100%"><input type="text" name="FORM_MSSQL_PREFIX" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'MSSQL_PREFIX'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap><input type="radio" name="FORM_DB_TYPE" value="oracle" $FORM{'ORACLE_CHECKED'}></td>
                      <td width="100%" nowrap colspan="3"><font face="Verdana" size="2">Use
                        Oracle (requires that <i>DBI</i> and <i>DBD::Oracle</i> are installed)</font></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Database
                        Name</font></b></td>
                      <td width="100%"><input type="text" name="FORM_ORACLE_DB_NAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ORACLE_DB_NAME'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><font size="2" face="Verdana"><b>Oracle Home Path (ORACLE_HOME)</b></font></td>
                      <td width="100%"><input type="text" name="FORM_ORACLE_SERVER" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ORACLE_SERVER'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><font size="2" face="Verdana"><b>TNS Admin Path (TNS_ADMIN)</b></font></td>
                      <td width="100%"><input type="text" name="FORM_ORACLE_PORT" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ORACLE_PORT'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Username</font></b></td>
                      <td width="100%"><input type="text" name="FORM_ORACLE_USERNAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ORACLE_USERNAME'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Password</font></b></td>
                      <td width="100%"><input type="text" name="FORM_ORACLE_PASSWORD" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ORACLE_PASSWORD'}"></td>
                    </tr>
                    <tr>
                      <td width="1" nowrap></td>
                      <td width="25" nowrap></td>
                      <td width="150" nowrap><b><font face="Verdana" size="2">Table Prefix</font></b></td>
                      <td width="100%"><input type="text" name="FORM_ORACLE_PREFIX" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ORACLE_PREFIX'}"></td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><font face="Verdana" size="2"><b>Mail System</b></font></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <table border="0" cellpadding="2" cellspacing="0" width="100%">
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Mail System </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top"><font face="Verdana" size="2"><input type="radio" name="FORM_MAIL_TYPE" value="SENDMAIL" $FORM{'SENDMAIL_CHECKED'}>
                  Sendmail<br>
                  <input type="radio" name="FORM_MAIL_TYPE" value="SMTP" $FORM{'SMTP_CHECKED'}> SMTP</font></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Sendmail Path</b></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_SENDMAIL" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'SENDMAIL'}"></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>SMTP Server</b></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_SMTP_SERVER" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'SMTP_SERVER'}"></td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><b><font face="Verdana" size="2">Misc. Options</font></b></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <table border="0" cellpadding="2" cellspacing="0" width="100%">
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Your Email Address </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_EMAIL" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'EMAIL'}"></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Server Time Offset</b></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_LOCALTIME_OFFSET" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'LOCALTIME_OFFSET'}"></td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><b><font face="Verdana" size="2">Administrator Account</font></b></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <table border="0" cellpadding="2" cellspacing="0" width="100%">
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Chosen Username </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_ADMIN_USERNAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ADMIN_USERNAME'}"></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Chosen Password </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_ADMIN_PASSWORD" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ADMIN_PASSWORD'}"></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"><font face="Verdana" size="2"><b>Chosen Name </b><font color="#FF0000" size="2" face="Verdana"><b>*</b></font></font></td>
                <td width="100%" valign="top"><input type="text" name="FORM_ADMIN_NAME" size="45" style="font-family: Verdana; font-size: 10pt; width: 100%" value="$FORM{'ADMIN_NAME'}"></td>
              </tr>
              <tr>
                <td width="200" nowrap valign="top"></td>
                <td width="100%" valign="top"><input type="submit" value="Next >" style="font-family: Verdana; font-size: 10pt">
                  <input type="reset" value="Cancel" style="font-family: Verdana; font-size: 10pt"></td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<input type="hidden" name="action" value="DoInstall">
<table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><td></form></td></tr></table>
</body>

</html>
HTML

  return 1;
}

###############################################################################
# DoInstall subroutine
sub DoInstall {
  my $Exit = eval {
    sub {
      print <<HTML;
</ul>
             </font>
           </td>
         </tr>
       </table>
     </td>
   </tr>
</table>
</body>

</html>
HTML

      exit;
    }
  };

  my %Fields = (
    "PATH"              => "Path",
    "PUBLIC_PATH"       => "Public Path",
    "URL"               => "URL",
    "PUBLIC_URL"        => "Public URL",
    "DB_TYPE"           => "Database Type",
    "MAIL_TYPE"         => "Mail Type",
    "EMAIL"             => "Your Email Address",
    "LOCALTIME_OFFSET"  => "Server Time Offset",
    "ADMIN_USERNAME"    => "Admin Username",
    "ADMIN_PASSWORD"    => "Admin Password",
    "ADMIN_NAME"        => "Admin Name"
  );
  
  my (%FORM, $Error);
  foreach my $key (keys %Fields) {
    if ($SD::QUERY{'FORM_'.$key} eq "") {
      $Error .= qq~<li>You didn't fill in the "$Fields{$key}" field.\n~;
    } else {
      $FORM{$key} = $SD::QUERY{'FORM_'.$key};
    }
  }
  
  if ($FORM{'DB_TYPE'} eq "mysql") {
    $FORM{'DB_SERVER'}    = $SD::QUERY{'FORM_MYSQL_SERVER'};
    $FORM{'DB_PORT'}      = $SD::QUERY{'FORM_MYSQL_PORT'};
    $FORM{'DB_NAME'}      = $SD::QUERY{'FORM_MYSQL_DB_NAME'};
    $FORM{'DB_USERNAME'}  = $SD::QUERY{'FORM_MYSQL_USERNAME'};
    $FORM{'DB_PASSWORD'}  = $SD::QUERY{'FORM_MYSQL_PASSWORD'};
    $FORM{'DB_PREFIX'}    = $SD::QUERY{'FORM_MYSQL_PREFIX'};
    
    $Error .= qq~<li>You didn't fill in the "Database Server" field.\n~ unless ($FORM{'DB_SERVER'});
    $Error .= qq~<li>You didn't fill in the "Database Port" field.\n~ unless ($FORM{'DB_PORT'});
    $Error .= qq~<li>You didn't fill in the "Database Name" field.\n~ unless ($FORM{'DB_NAME'});
    $Error .= qq~<li>You didn't fill in the "Database Username" field.\n~ unless ($FORM{'DB_USERNAME'});
    $Error .= qq~<li>You didn't fill in the "Database Password" field.\n~ unless ($FORM{'DB_PASSWORD'});
    $Error .= qq~<li>You didn't fill in the "Table Prefix" field.\n~ unless ($FORM{'DB_PREFIX'});
  } elsif ($FORM{'DB_TYPE'} eq "mssql") {
    $FORM{'DB_NAME'}      = $SD::QUERY{'FORM_MSSQL_DB_NAME'};
    $FORM{'DB_USERNAME'}  = $SD::QUERY{'FORM_MSSQL_USERNAME'};
    $FORM{'DB_PASSWORD'}  = $SD::QUERY{'FORM_MSSQL_PASSWORD'};
    $FORM{'DB_PREFIX'}    = $SD::QUERY{'FORM_MSSQL_PREFIX'};

    $Error .= qq~<li>You didn't fill in the "Database Name" field.\n~ unless ($FORM{'DB_NAME'});
    $Error .= qq~<li>You didn't fill in the "Database Username" field.\n~ unless ($FORM{'DB_USERNAME'});
    $Error .= qq~<li>You didn't fill in the "Database Password" field.\n~ unless ($FORM{'DB_PASSWORD'});
    $Error .= qq~<li>You didn't fill in the "Table Prefix" field.\n~ unless ($FORM{'DB_PREFIX'});
  } elsif ($FORM{'DB_TYPE'} eq "oracle") {
    $FORM{'DB_SERVER'}    = $SD::QUERY{'FORM_ORACLE_SERVER'};
    $FORM{'DB_PORT'}      = $SD::QUERY{'FORM_ORACLE_PORT'};
    $FORM{'DB_NAME'}      = $SD::QUERY{'FORM_ORACLE_DB_NAME'};
    $FORM{'DB_USERNAME'}  = $SD::QUERY{'FORM_ORACLE_USERNAME'};
    $FORM{'DB_PASSWORD'}  = $SD::QUERY{'FORM_ORACLE_PASSWORD'};
    $FORM{'DB_PREFIX'}    = $SD::QUERY{'FORM_ORACLE_PREFIX'};
    
    $Error .= qq~<li>You didn't fill in the "Database Server" field.\n~ unless ($FORM{'DB_SERVER'});
    $Error .= qq~<li>You didn't fill in the "Database Port" field.\n~ unless ($FORM{'DB_PORT'});
    $Error .= qq~<li>You didn't fill in the "Database Name" field.\n~ unless ($FORM{'DB_NAME'});
    $Error .= qq~<li>You didn't fill in the "Database Username" field.\n~ unless ($FORM{'DB_USERNAME'});
    $Error .= qq~<li>You didn't fill in the "Database Password" field.\n~ unless ($FORM{'DB_PASSWORD'});
    $Error .= qq~<li>You didn't fill in the "Table Prefix" field.\n~ unless ($FORM{'DB_PREFIX'});
  }

  if ($FORM{'MAIL_TYPE'} eq "SENDMAIL") {
    $FORM{'SENDMAIL'} = $SD::QUERY{'FORM_SENDMAIL'};
    $Error .= qq~<li>You didn't fill in the "Sendmail Path" field.\n~ unless ($FORM{'SENDMAIL'});
  } else {
    $FORM{'SMTP_SERVER'} = $SD::QUERY{'FORM_SMTP_SERVER'};
    $Error .= qq~<li>You didn't fill in the "SMTP Server" field.\n~ unless ($FORM{'SMTP_SERVER'});
  }
  
  &Install(ERROR => $Error) and return 1 if ($Error);

  print <<HTML;
<html>

<head>
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<meta name="GENERATOR" content="Microsoft FrontPage 4.0">
<meta name="ProgId" content="FrontPage.Editor.Document">
<title>SuperDesk Installation</title>
<style>
<!--
a            { text-decoration: none }
a:hover      { text-decoration: underline }
-->
</style>
</head>

<body topmargin="5" leftmargin="5" marginheight="5" marginwidth="5" text="#333333" link="#3366CC" vlink="#3366CC" alink="#3366CC">

<table border="0" cellpadding="0" cellspacing="1" width="100%" bgcolor="#333333">
  <tr>
    <td width="100%" bgcolor="#FFFFFF">
      <table border="0" cellpadding="4" cellspacing="1" width="100%" bgcolor="#333333">
        <tr>
          <td width="100%"><font face="Verdana" size="1" color="#FFFFFF"><b>superdesk installation</b></font></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><b><font face="Verdana" size="2">Installation Process</font></b></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <font face="Verdana" size="2">
            <ul>
HTML

  print qq~<li>Checking Path... ~;
  if (-e $FORM{'PATH'}) {
    print qq~<font color="Green">Path found.</font>\n~;
  }  else {
    print qq~<font color="Red">Path not found. Please check it and try again.</font>\n~ and &$Exit;
  }

  print qq~<li>Checking Public Path... ~;
  if (-e $FORM{'PUBLIC_PATH'}) {
    print qq~<font color="Green">Path found.</font>\n~;
  }  else {
    print qq~<font color="Red">Path not found. Please check it and try again.</font>\n~ and &$Exit;
  }

  print qq~<li>Checking URL... ~;
  $FORM{'URL'} =~ s/\\/\//g;
  $FORM{'URL'} =~ s/\/$//g;
  if ($FORM{'URL'} =~/^http(s)?:\/\//i) {
    print qq~<font color="Green">Seems OK.</font>\n~;
  } else {
    print qq~<font color="Red">URL is incorrect. Please check it and try again.</font>\n~ and &$Exit;
  }

  print qq~<li>Checking Public URL... ~;
  $FORM{'PUBLIC_URL'} =~ s/\\/\//g;
  $FORM{'PUBLIC_URL'} =~ s/\/$//g;
  if ($FORM{'PUBLIC_URL'} =~/^http(s)?:\/\//i) {
    print qq~<font color="Green">Seems OK.</font>\n~;
  } else {
    print qq~<font color="Red">URL is incorrect. Please check it and try again.</font>\n~ and &$Exit;
  }
  
  print qq~<li>Checking Private.tar... ~;
  if (-e "$FORM{'PATH'}/Private.tar") {
    open(FILE, "$FORM{'PATH'}/Private.tar") || (print qq~<font color="Red">Error opening file for reading. $!.</font>\n~ and &$Exit);
    binmode(FILE);
    my $checksum = do {
      local $/;
      unpack("%32C*", <FILE>) % 65535;
    };
    close(FILE);
    
    if ($checksum != 24654) {
      print qq~<font color="Red">A CRC check on the file failed. Please check that it is the original file and that you uploaded it in BINARY mode.</font>\n~ and &$Exit;
    }
  } else {
    print qq~<font color="Red">Can't find Private.tar file. Please check that the file exists in $FORM{'PATH'}.</font>\n~ and &$Exit;
  }
  print qq~<font color="Green">Seems OK.</font>\n~;
  
  print qq~<li>Unpacking Private.tar into $FORM{'PATH'}... ~;
  my $Cwd = cwd() || $SD::PATH;

  my $Tar = Archive::Tar->new();
  unless ($Tar->read("$FORM{'PATH'}/Private.tar", 0)) {
    print qq~<font color="Red">Error reading Private.tar file. $!.</font>\n~ and &$Exit;
  }

  chdir($FORM{'PATH'});
  my @Files = $Tar->list_files();
  $Tar->extract(@Files, $FORM{'PATH'});
  chdir($Cwd);
  print qq~<font color="Green">All files should be extracted.</font>\n~;

  print qq~<li>Checking that files were extracted correctly... ~;
  my $error;
  foreach my $file (@Files) {
    unless (-e "$FORM{'PATH'}/$file") {
      $error = 1;
      last;
    }
  }
  if ($error) {
    print qq~<font color="Red">One or more files were not extracted correctly. Please check the directory permissions and try again.</font>\n~ and &$Exit;
  } else {
    print qq~<font color="Green">All extracted OK.</font>\n~;
  }

  print qq~<li>Checking for Private directory... ~;
  if (-e "$FORM{'PATH'}/Private") {
    print qq~<font color="Green">Path found.</font>\n~;
  } else {
    print qq~<font color="Red">Path not found. Please create it and CHMOD it to 777.</font>\n~ and &$Exit;
  }

  print qq~<li>Creating extra directories... ~;
  my @Directories = (
    "$FORM{'PATH'}/Private/Database",
    "$FORM{'PATH'}/Private/Database/Temp",
    "$FORM{'PATH'}/Private/Database/Temp/Cache",
    "$FORM{'PATH'}/Private/Database/Temp/Mail",
    "$FORM{'PATH'}/Private/Logs",
    "$FORM{'PATH'}/Private/Backups",
    "$FORM{'PATH'}/Private/Plugins",
    "$FORM{'PUBLIC_PATH'}/Attachments"
  );
  foreach my $dir (@Directories) {
    if (-e $dir) {
      rmtree($dir) || (print qq~<font color="Red">Error removing existing $dir. $!.</font>\n~ and &$Exit);
    }
    mkdir($dir, 0777) || (print qq~<font color="Red">Error creating $dir. $!.</font>\n~ and &$Exit);
    chmod(0777, $dir);
  }
  print qq~<font color="Green">All directories should be created now.</font>\n~;

  print qq~<li>Writing system variable file... ~;
  my $Variables;
  eval {
    require "$FORM{'PATH'}/Private/Modules/Libraries/Variables.pm.pl";
    $Variables = Variables->new();
  } || (print qq~<font color="Red">Error requiring Variables.pm.pl library. $@.</font>\n~ and &$Exit);

  $Variables->Update(
    FILE      => "$FORM{'PATH'}/Private/Variables/System.pm.pl",
    PACKAGE   => "System",
    VARIABLE  => "SYSTEM",
    VALUES    => {
      "INSTALLED"         => "1",
      "DB_PATH"           => "$FORM{'PATH'}/Private/Database",
      "TEMP_PATH"         => "$FORM{'PATH'}/Private/Database/Temp",
      "LOGS_PATH"         => "$FORM{'PATH'}/Private/Logs",
      "BACKUP_PATH"       => "$FORM{'PATH'}/Private/Backups",
      "CACHE_PATH"        => "$FORM{'PATH'}/Private/Database/Temp/Cache",
      "PUBLIC_PATH"       => "$FORM{'PUBLIC_PATH'}",
      
      "SCRIPT_URL"        => "$FORM{'URL'}/SuperDesk.$SD::EXTENSION",
      "PUBLIC_URL"        => "$FORM{'PUBLIC_URL'}",
      
      "DB_TYPE"           => $FORM{'DB_TYPE'},
      
      "DB_PREFIX"         => $FORM{'DB_PREFIX'},
      "DB_HOST"           => $FORM{'DB_SERVER'},
      "DB_PORT"           => $FORM{'DB_PORT'},
      "DB_NAME"           => $FORM{'DB_NAME'},
      "DB_USERNAME"       => $FORM{'DB_USERNAME'},
      "DB_PASSWORD"       => $FORM{'DB_PASSWORD'},
      
      "MAIL_TYPE"         => $FORM{'MAIL_TYPE'},
      "SENDMAIL"          => $FORM{'SENDMAIL'},
      "SMTP_SERVER"       => $FORM{'SMTP_SERVER'},
      
      "LOCALTIME_OFFSET"  => $FORM{'LOCALTIME_OFFSET'}
    }
  ) || (print qq~<font color="Red">Error writing to the System.pm.pl file in $FORM{'PATH'}/Private/Variables. $Variables->{'ERROR'}. Please check that it exists and try again.</font>\n~ and &$Exit);
  print qq~<font color="Green">Complete.</font>\n~;

  print qq~<li>Writing general variable file... ~;
  $Variables->Update(
    FILE      => "$FORM{'PATH'}/Private/Variables/General.pm.pl",
    PACKAGE   => "General",
    VARIABLE  => "GENERAL",
    VALUES    => {
      "CONTACT_EMAIL"   => $FORM{'EMAIL'},
      "ADMIN_EMAIL"     => $FORM{'EMAIL'}
    }
  ) || (print qq~<font color="Red">Error writing to the General.pm.pl file in $FORM{'PATH'}/Private/Variables. $Variables->{'ERROR'}. Please check that it exists and try again.</font>\n~ and &$Exit);
  print qq~<font color="Green">Complete.</font>\n~;

  print qq~<li>Checking for recommended modules...\n~;
  print qq~<ul>\n~;
  my %Modules = (
    "Compress::Zlib"    => "You will not be able to compress backups into .tar.gz archives",
    "LWP"               => "You will not be able to use the Update feature",
    "MIME::Base64"      => "You will not be able to send attachments to users",
    "MIME::QuotedPrint" => "You will not be able to send attachments to users",
    "MIME::Parser"      => "You will not be able to use the ProcessEmail.pl utility script to point email addresses at SuperDesk",
    "Mail::Internet"    => "You will not be able to use the ProcessEmail.pl utility script to point email addresses at SuperDesk"
  );
  foreach my $module (keys %Modules) {
    print qq~<li>Checking $module module... ~;
    eval "use ".$module;
    if ($@) {
      print qq~<font color="Olive">Could not find $module module. $Modules{$module}.</font>\n~;
    } else {
      print qq~<font color="Green">Module found.</font>\n~;
    }
  }
  print qq~</ul>\n~;

  if ($FORM{'DB_TYPE'} eq "mysql") {
    print qq~<li>You chose to use the MySQL database engine.<br>\n~;
    print qq~<ul>\n~;
    print qq~<li>Checking DBI module... ~;
    eval "use DBI";
    if ($@) {
      print qq~<font color="Red">Could not find DBI module. Please check that DBI is available to use on your system and try again.</font>\n~ and &$Exit;
    } else {
      print qq~<font color="Green">Module found.</font>\n~;
    }

    print qq~<li>Checking the MySQL driver... ~;
    my $found = 0;
    my @drivers = DBI->available_drivers();
    foreach my $driver (@drivers) {
      $found = 1 and last if (index($driver, "mysql") != -1);
    }
    if ($found) {
      print qq~<font color="Green">Driver found.</font>\n~;
    } else {
      print qq~<font color="Red">Could not find a MySQL driver. Please check that a MySQL driver (DBD::MYSQL) is available for use on your system and try again.</font>\n~ and &$Exit;
    }

    print qq~<li>Trying to connect to the database... ~;
    $found = 0;
    my $DSN  = "DBI:mysql:$FORM{'DB_NAME'}:$FORM{'DB_SERVER'}";
       $DSN .= ":$FORM{'DB_PORT'}" if ($FORM{'DB_PORT'});
    my $DBH ||= DBI->connect($DSN, $FORM{'DB_USERNAME'}, $FORM{'DB_PASSWORD'}) || (print qq~<font color="Red">Couldn't connect to the database server ($FORM{'DB_SERVER'}) and database ($FORM{'DB_NAME'}). $DBI::errstr</font>\n~ and &$Exit);
    my $STH = $DBH->prepare("SHOW DATABASES");
       $STH->execute();
    while (my @log = $STH->fetchrow_array()) {
      $found = 1 if ($log[0] eq $FORM{'DB_NAME'});
    }
    if ($found) {
      print qq~<font color="Green">Connected OK.</font>\n~;
    } else {
      print qq~<font color="Red">Couldn't find the database ($FORM{'DB_NAME'}). Please check to see if the database has been created and check to see that the permissions on the MySQL username ($FORM{'DB_USERNAME'}) are correct.</font>\n~ and &$Exit;
    }
    $DBH->disconnect();
    
    print qq~</ul>\n~;
  } elsif ($FORM{'DB_TYPE'} eq "mssql") {
    print qq~<li>You chose to use the Microsoft SQL Server database engine.\n~;
    print qq~<ul>\n~;
    print qq~<li>Checking the Win32::ODBC module... ~;
    eval "use Win32::ODBC";
    if ($@) {
      print qq~<font color="Red">Couldn't find the Win32::ODBC module. Please check that it is installed on the server and try again.</font>\n~ and &$Exit;
    } else {
      print qq~<font color="Green">Found OK.</font>\n~;
    }
    print qq~<li>Trying to connect to the database... ~;
    my $DSN = "dsn=$FORM{'DB_NAME'}";
       $DSN .= "; uid=$FORM{'DB_USERNAME'}" if ($FORM{'DB_USERNAME'});
       $DSN .= "; pwd=$FORM{'DB_PASSWORD'}" if ($FORM{'DB_PASSWORD'});
    my $DBH = Win32::ODBC->new($DSN);
    if ($DBH->{'connection'}) {
      print qq~<font color="Green">Connected OK.</font>\n~;
    } else {
      print qq~<font color="Red">Couldn't connect to the data source ($FORM{'DB_NAME'}). $DBH->Error</font>\n~;
    }
    $DBH->Close();
    
    print qq~</ul>\n~;
  } elsif ($FORM{'DB_TYPE'} eq "oracle") {
    print qq~<li>You chose to use the Oracle database engine.<br>\n~;
    print qq~<ul>\n~;
    print qq~<li>Checking DBI module... ~;
    eval "use DBI";
    if ($@) {
      print qq~<font color="Red">Could not find DBI module. Please check that DBI is available to use on your system and try again.</font>\n~ and &$Exit;
    } else {
      print qq~<font color="Green">Module found.</font>\n~;
    }

    print qq~<li>Checking the Oracle driver... ~;
    my $found = 0;
    my @drivers = DBI->available_drivers();
    foreach my $driver (@drivers) {
      $found = 1 and last if (index($driver, "Oracle") != -1);
    }
    if ($found) {
      print qq~<font color="Green">Driver found.</font>\n~;
    } else {
      print qq~<font color="Red">Could not find an Oracle driver. Please check that an Oracle driver (DBD::Oracle) is available for use on your system and try again.</font>\n~ and &$Exit;
    }

    print qq~<li>Trying to connect to the database... ~;
    $ENV{'ORACLE_HOME'} = $FORM{'DB_SERVER'};
    $ENV{'TNS_ADMIN'}   = $FORM{'DB_PORT'};
    my $DSN  = "DBI:Oracle:$FORM{'DB_NAME'}";
    my $DBH ||= DBI->connect($DSN, $FORM{'DB_USERNAME'}, $FORM{'DB_PASSWORD'});
    if ($DBH) {
      print qq~<font color="Green">Connected OK.</font>\n~;
    } else {
      print qq~<font color="Red">Couldn't connect to the database server and database ($FORM{'DB_NAME'}). $DBI::errstr</font>\n~ and &$Exit;
    }
    $DBH->disconnect();

    print qq~</ul>\n~;
  } else {
    print qq~<li>You chose to use the DBM database engine.<br>\n~;
    print qq~<ul>\n~;
    print qq~<li>Checking for a DBM module... ~;
    my $found = 0;
    foreach my $module ("DB_File", "GDBM_File", "NDBM_File", "SDBM_File") {
      eval "use $module";
      $found = 1 and last unless ($@);
    }
    if ($found) {
      print qq~<font color="Green">Module found.</font>\n~;
    } else {
      print qq~<font color="Red">Could not find a suitable DBM module. Please check that a DBM module (DB_File, GDBM_File, NDBM_File or SDBM_File) is available to use on your system and try again.</font>\n~ and &$Exit;
    }
    print qq~</ul>\n~;
  }

  print qq~<li>Checking to see that SuperDesk.cgi/pl exists... ~;
  if (-e "$FORM{'PATH'}/SuperDesk.cgi" || -e "$FORM{'PATH'}/SuperDesk.pl") {
    print qq~<font color="Green">Found OK.</font>\n~;
  } else {
    print qq~<font color="Olive">File not found. Please check that it exists.</font>\n~;
  }

  if ($SD::EXTENSION ne "cgi" && !(-e "$FORM{'PATH'}/SuperDesk.$SD::EXTENSION") && (-e "$FORM{'PATH'}/SuperDesk.cgi")) {
    print qq~<li>Renaming SuperDesk.cgi to SuperDesk.$SD::EXTENSION... ~;
    if (rename("$FORM{'PATH'}/SuperDesk.cgi", "$FORM{'PATH'}/SuperDesk.$SD::EXTENSION")) {
      print qq~<font color="Green">Renamed OK.</font>\n~;
    } else {
      print qq~<font color="Olive">Couldn't rename file. Please rename it manually.</font>\n~;
    }
  }

  print qq~<li>Checking path to Perl... ~;  
  if (open(INSTALL, "$FORM{'PATH'}/install.$SD::EXTENSION")) {
    my @install = <INSTALL>;
    close(INSTALL);
    my $perlpath = $install[0] || "#!/usr/bin/perl";

    if (open(SUPERDESK, "$FORM{'PATH'}/SuperDesk.$SD::EXTENSION")) {
      my @superdesk = <SUPERDESK>;
      close(SUPERDESK);
  
      if ($superdesk[0] ne $perlpath) {
        print qq~Changing path to Perl in SuperDesk.$SD::EXTENSION... ~;
        if (open(SUPERDESK, ">$FORM{'PATH'}/SuperDesk.$SD::EXTENSION")) {
          $superdesk[0] = $perlpath;
          print SUPERDESK join("", @superdesk);
          close(SUPERDESK);
          print qq~<font color="Green">Done.</font>\n~;
        } else {
          $perlpath =~ s/^#\!//;
          print qq~<font color="Olive">Couldn't write to SuperDesk.$SD::EXTENSION. You will need to change the path to Perl manually to "$perlpath".</font>\n~;
        }
      } else {
        print qq~<font color="Green">Path is OK.</font>\n~;
      }
    } else {
      print qq~<font color="Olive">Couldn't read from SuperDesk.$SD::EXTENSION. You may need to change the path to Perl manually.</font>\n~;
    }
  } else {
    print qq~<font color="Olive">Couldn't read from install.$SD::EXTENSION. You may need to change the path to Perl manually.</font>\n~;
  }

  print qq~</ul>\n~;

  print <<HTML;
<p>The first stage of the installation is complete. Please click the button below to continue:
<p><table cellpadding="0" cellspacing="0" border="0" width="100%"><form name="form" method="POST" action="$FORM{'URL'}/install.$SD::EXTENSION">
  <tr>
    <td align="center"><input type="submit" value="Next >" style="font-family: Verdana; font-size: 10pt; width: 100"></td>
  </tr>
</table>
<input type="hidden" name="action" value="CreateTables">
<input type="hidden" name="FORM_PATH" value="$FORM{'PATH'}">
<input type="hidden" name="FORM_URL" value="$FORM{'URL'}">
<input type="hidden" name="FORM_DB_TYPE" value="$FORM{'DB_TYPE'}">
<input type="hidden" name="FORM_ADMIN_USERNAME" value="$FORM{'ADMIN_USERNAME'}">
<input type="hidden" name="FORM_ADMIN_PASSWORD" value="$FORM{'ADMIN_PASSWORD'}">
<input type="hidden" name="FORM_ADMIN_NAME" value="$FORM{'ADMIN_NAME'}">
<input type="hidden" name="FORM_EMAIL" value="$FORM{'EMAIL'}">
             </font>
           </td>
         </tr>
       </table>
     </td>
   </tr>
</table>
</body>

</html>
HTML

  return 1;
}

###############################################################################
# CreateTables subroutine
sub CreateTables {
  my $Exit = eval {
    sub {
      print <<HTML;
</ul>
             </font>
           </td>
         </tr>
       </table>
     </td>
   </tr>
</table>
</body>

</html>
HTML

      exit;
    }
  };

  my %FORM = (
    "PATH"            => $SD::QUERY{'FORM_PATH'},
    "URL"             => $SD::QUERY{'FORM_URL'},
    "DB_TYPE"         => $SD::QUERY{'FORM_DB_TYPE'},
    "EMAIL"           => $SD::QUERY{'FORM_EMAIL'},
    "ADMIN_USERNAME"  => $SD::QUERY{'FORM_ADMIN_USERNAME'},
    "ADMIN_PASSWORD"  => $SD::QUERY{'FORM_ADMIN_PASSWORD'},
    "ADMIN_NAME"      => $SD::QUERY{'FORM_ADMIN_NAME'}
  );

  print <<HTML;
<html>

<head>
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<meta name="GENERATOR" content="Microsoft FrontPage 4.0">
<meta name="ProgId" content="FrontPage.Editor.Document">
<title>SuperDesk Installation</title>
<style>
<!--
a            { text-decoration: none }
a:hover      { text-decoration: underline }
-->
</style>
</head>

<body topmargin="5" leftmargin="5" marginheight="5" marginwidth="5" text="#333333" link="#3366CC" vlink="#3366CC" alink="#3366CC">

<table border="0" cellpadding="0" cellspacing="1" width="100%" bgcolor="#333333">
  <tr>
    <td width="100%" bgcolor="#FFFFFF">
      <table border="0" cellpadding="4" cellspacing="1" width="100%" bgcolor="#333333">
        <tr>
          <td width="100%"><font face="Verdana" size="1" color="#FFFFFF"><b>superdesk installation</b></font></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#CCCCCC"><b><font face="Verdana" size="2">Installation Process</font></b></td>
        </tr>
        <tr>
          <td width="100%" bgcolor="#EEEEEE">
            <font face="Verdana" size="2">
            <ul>
HTML

  print qq~<li>Creating tables...\n~;
  print qq~<ul>\n~;
  
  unshift(@INC, "$FORM{'PATH'}");
  unshift(@INC, "$FORM{'PATH'}/Private");
  unshift(@INC, "$FORM{'PATH'}/Private/Modules");
  unshift(@INC, "$FORM{'PATH'}/Private/Modules/Libraries");
  unshift(@INC, "$FORM{'PATH'}/Private/Variables");

  require "Database.$FORM{'DB_TYPE'}.pm.pl";
  my $DB = Database->new();
  
  print qq~<li>Creating Categories table... ~;
  (
    $DB->CreateTable(
      TABLE       => "Categories",
      VALUE       => {
        ID                  => [ 0, "autonumber",    16, 1,           ""],
        NAME                => [ 1,     "string",    64, 1,           ""],
        DESCRIPTION         => [ 2,     "string",   256, 0,           ""],
        CONTACT_NAME        => [ 3,     "string",   128, 0,           ""],
        CONTACT_EMAIL       => [ 4,     "string",   128, 0,           ""]
      },
      PRIMARY_KEY => "ID"
    )
  ) || (print qq~<font color="Red">Error creating table. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Table created OK.</font>\n~;
  
  print qq~<li>Creating Notes table... ~;
  (
    $DB->CreateTable(
      TABLE       => "Notes",
      VALUE       => {
        ID                  => [ 0, "autonumber",    16, 1,           ""],
        TID                 => [ 1,     "number",    16, 1,           ""],
        SUBJECT             => [ 2,     "string",   256, 1,           ""],
        MESSAGE             => [ 3,       "text",    -1, 1,           ""],
        ATTACHMENTS         => [ 4,     "string", 32768, 0,           ""],
        AUTHOR              => [ 5,     "string",    64, 0,           ""],
        AUTHOR_TYPE         => [ 6,     "string",    16, 1,           ""],
        DELIVERY_METHOD     => [ 7,     "string",    16, 1,           ""],
        PRIVATE             => [ 8,     "number",     1, 0,          "0"],
        CREATE_SECOND       => [ 9,     "number",    16, 1,           ""],
        CREATE_DATE         => [10,     "string",    64, 1,           ""],
        CREATE_TIME         => [11,     "string",    64, 1,           ""],
        UPDATE_SECOND       => [12,     "number",    16, 0,           ""],
        UPDATE_DATE         => [13,     "string",    64, 0,           ""],
        UPDATE_TIME         => [14,     "string",    64, 0,           ""]
      },
      PRIMARY_KEY => "ID"
    )
  ) || (print qq~<font color="Red">Error creating table. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Table created OK.</font>\n~;

  print qq~<li>Creating Sessions table... ~;
  (
    $DB->CreateTable(
      TABLE       => "Sessions",
      VALUE       => {
        ID                  => [ 0, "autonumber",    16, 1,           ""],
        USERNAME            => [ 1,     "string",    48, 1,           ""],
        PASSWORD            => [ 2,     "string",    64, 1,           ""],
        IP                  => [ 3,     "string",    16, 1,           ""],
        LOGIN_SECOND        => [ 4,     "number",    16, 1,           ""]
      },
      PRIMARY_KEY => "ID"
    )
  ) || (print qq~<font color="Red">Error creating table. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Table created OK.</font>\n~;

  print qq~<li>Creating StaffAccounts table... ~;
  (
    $DB->CreateTable(
      TABLE       => "StaffAccounts",
      VALUE       => {
        USERNAME                  => [ 0,     "string",    48, 1,           ""],
        PASSWORD                  => [ 1,     "string",    64, 1,           ""],
        NAME                      => [ 2,     "string",   128, 1,           ""],
        EMAIL                     => [ 3,     "string",   128, 1,           ""],
        STATUS                    => [ 4,     "number",     3, 1,           ""],
        LEVEL                     => [ 5,     "number",     3, 1,           ""],
        CATEGORIES                => [ 6,     "string", 32768, 0,           ""],
        SIGNATURE                 => [ 7,     "string",   512, 0,           ""],
        NOTIFY_NEW_TICKETS        => [ 8,     "number",     1, 0,           ""],
        NOTIFY_NEW_NOTES_UNOWNED  => [ 9,     "number",     1, 0,           ""],
        NOTIFY_NEW_NOTES_OWNED    => [10,     "number",     1, 0,           ""]
      },
      PRIMARY_KEY => "USERNAME"
    )
  ) || (print qq~<font color="Red">Error creating table. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Table created OK.</font>\n~;

  print qq~<li>Creating Tickets table... ~;
  (
    $DB->CreateTable(
      TABLE       => "Tickets",
      VALUE       => {
        ID                  => [ 0, "autonumber",    16, 1,           ""],
        SUBJECT             => [ 1,     "string",   256, 1,           ""],
        CATEGORY            => [ 2,     "number",    16, 1,           ""],
        AUTHOR              => [ 3,     "string",    48, 0,           ""],
        EMAIL               => [ 4,     "string",   128, 1,           ""],
        GUEST_NAME          => [ 5,     "string",   256, 0,           ""],
        DELIVERY_METHOD     => [ 6,     "string",    16, 1,           ""],
        PRIORITY            => [ 7,     "number",     3, 1,           ""],
        SEVERITY            => [ 8,     "number",     3, 1,           ""],
        STATUS              => [ 9,     "number",     3, 1,           ""],
        OWNED_BY            => [10,     "string",    48, 0,           ""],
        CREATE_SECOND       => [11,     "number",    16, 1,           ""],
        CREATE_DATE         => [12,     "string",    64, 1,           ""],
        CREATE_TIME         => [13,     "string",    64, 1,           ""],
        UPDATE_SECOND       => [14,     "number",    16, 0,           ""],
        UPDATE_DATE         => [15,     "string",    64, 0,           ""],
        UPDATE_TIME         => [16,     "string",    64, 0,           ""],
        NOTES               => [17,     "number",    16, 0,           ""]
      },
      PRIMARY_KEY => "ID"
    )
  ) || (print qq~<font color="Red">Error creating table. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Table created OK.</font>\n~;

  print qq~<li>Creating UserAccounts table... ~;
  (
    $DB->CreateTable(
      TABLE       => "UserAccounts",
      VALUE       => {
        USERNAME            => [ 0,     "string",    48, 1,           ""],
        PASSWORD            => [ 1,     "string",    64, 1,           ""],
        NAME                => [ 2,     "string",   128, 1,           ""],
        EMAIL               => [ 3,     "string",   128, 1,           ""],
        OTHER_EMAILS        => [ 4,     "string", 32768, 0,           ""],
        URL                 => [ 5,     "string",   256, 0,           ""],
        STATUS              => [ 6,     "number",     3, 1,           ""],
        LEVEL               => [ 7,     "number",     3, 1,           ""],
        CREATE_SECOND       => [ 8,     "number",    16, 1,           ""],
        CREATE_DATE         => [ 9,     "string",    64, 1,           ""],
        CREATE_TIME         => [10,     "string",    64, 1,           ""]
      },
      PRIMARY_KEY => "USERNAME"
    )
  ) || (print qq~<font color="Red">Error creating table. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Table created OK.</font>\n~;

  print qq~</ul>\n~;

  print qq~<li>Creating Admin account... ~;
  (
    $DB->Insert(
      TABLE   => "StaffAccounts",
      VALUES  => {
        USERNAME                  => $FORM{'ADMIN_USERNAME'},
        PASSWORD                  => $FORM{'ADMIN_PASSWORD'},
        NAME                      => $FORM{'ADMIN_NAME'},
        EMAIL                     => $FORM{'EMAIL'},
        STATUS                    => "50",
        LEVEL                     => "100",
        CATEGORIES                => "*",
        NOTIFY_NEW_TICKETS        => "1",
        NOTIFY_NEW_NOTES_UNOWNED  => "1",
        NOTIFY_NEW_NOTES_OWNED    => "1"
      }
    )
  ) || (print qq~<font color="Red">Error creating account. $DB->{'ERROR'}.</font>\n~ and &$Exit);
  print qq~<font color="Green">Account created OK.</font>\n~;

  print qq~<li>Removing installation files...\n~;
  print qq~<ul>\n~;
  print qq~<li>Removing install.$SD::EXTENSION... ~;
  if (unlink("$FORM{'PATH'}/install.$SD::EXTENSION")) {
    print qq~<font color="Green">Done.</font>\n~;
  } else {
    print qq~<font color="Olive">Couldn't remove file. Please remove it manually.</font>\n~;
  }
  print qq~<li>Removing Private.tar... ~;
  if (unlink("$FORM{'PATH'}/Private.tar")) {
    print qq~<font color="Green">Done.</font>\n~;
  } else {
    print qq~<font color="Olive">Couldn't remove file. Please remove it manually.</font><br>\n~;
  }
  print qq~<li>Removing Archive/Tar.pm... ~;
  if (unlink("$FORM{'PATH'}/Archive/Tar.pm")) {
    print qq~<font color="Green">Done.</font><br>\n~;
  } else {
    print qq~<font color="Olive">Couldn't remove file. Please remove it manually.</font><br>\n~;
  }
  print qq~<li>Removing Archive directory... ~;
  if (rmdir("$FORM{'PATH'}/Archive")) {
    print qq~<font color="Green">Done.</font>\n~;
  } else {
    print qq~<font color="Olive">Couldn't remove directory. Please remove it manually.</font>\n~;
  }
  print qq~</ul>\n~;
  
  print qq~</ul>\n~;

  print qq~<p><b>Installation should now be complete!</b>~;
  print <<HTML;
<p>You can now <a href="$FORM{'URL'}/SuperDesk.$SD::EXTENSION?CP=1" target="_blank">click here</a> to go straight to the SuperDesk Control Panel.
<!--We would also greatly appreciate it if you would now take the time to rate SuperDesk using the following dropdown boxes:

<p align="center"><table cellpadding="3" cellspacing="1" border="0"><form method="POST" action="http://cgi-resources.com/rate/index.cgi" target="_blank">
  <tr>
    <td colspan="3" bgcolor="#DDDDDD"><font face="Verdana" size="2"><b><a href="http://www.cgi-resources.com" target="_blank">The CGI Resource Index</a></b></font></td>
  </tr>
  <tr>
    <td bgcolor="#DDDDDD"><font face="Verdana" size="2"><b>Rating</b></font></td>
    <td bgcolor="#DDDDDD">
      <select name="rating" style="font-family: Verdana; font-size: 10pt; width: 150">
        <option>---
        <option>1
        <option>2
        <option>3
        <option>4
        <option>5
        <option>6
        <option>7
        <option>8
        <option>9
        <option>10
      </select>
    </td>
    <td bgcolor="#DDDDDD"><input type="submit" value="Rate!" style="font-family: Verdana; font-size: 10pt"></td>
  </tr>
  <tr>
    <td bgcolor="#DDDDDD"></td>
    <td colspan="2" bgcolor="#DDDDDD"><font face="Verdana" size="1">(1 = Lowest, 10 = Highest)</font></td>
  </tr>
</table>
<input type="hidden" name="referer" value="http://cgi-resources.com/">
<input type="hidden" name="link_code" value="05961">
<input type="hidden" name="category_name" value="Programs and Scripts/Perl/Link Indexing Scripts/Directories and Portals/">
<input type="hidden" name="link_name" value="SuperLinks">
<table cellpadding="0" cellspacing="0" border="0"><tr><td></form></td></tr></table>

<p align="center"><table cellpadding="3" cellspacing="1" border="0"><form method="POST" action="http://www.hotscripts.com/cgi-bin/rate.cgi" target="_blank">
  <tr>
    <td colspan="3" bgcolor="#DDDDDD"><font face="Verdana" size="2"><b><a href="http://www.hotscripts.com" target="_blank">HotScripts</a></b></font></td>
  </tr>
  <tr>
    <td bgcolor="#DDDDDD"><font face="Verdana" size="2"><b>Rating</b></font></td>
    <td bgcolor="#DDDDDD">
      <select name="rate" style="font-family: Verdana; font-size: 10pt; width: 150">
      <option>---
      <option value="1">Poor
      <option value="2">Fair
      <option value="3">Good
      <option value="4">Very Good
      <option value="5">Excellent
      </select>
    </td>
    <td bgcolor="#DDDDDD"><input type="submit" value="Rate!" style="font-family: Verdana; font-size: 10pt"></td>
  </tr>
</table>
<input type="hidden" name="ID" value="8906">
<table cellpadding="0" cellspacing="0" border="0"><tr><td></form></td></tr></table>-->

             </font>
           </td>
         </tr>
       </table>
     </td>
   </tr>
</table>
</body>

</html>
HTML

  return 1;
}

###############################################################################
# CGIError subroutine
# Prints a CGI error
sub CGIError {
  my ($message, $path) = @_;

  my ($key, $space);

  $message =~ s/\n/<br>/g;

  if ($SD::HTML_HEADER != 1) {
    print "Content-Type: text/html\n\n";
  }

  print "<html>\n";
  print "<head>\n";
  print "<title>CGI Script Error</title>\n";
  print "</head>\n";
  print "<body marginheight=\"5\" marginwidth=\"5\" leftmargin=\"5\" topmargin=\"5\" rightmargin=\"5\">\n";
  print "<font face=\"Verdana\">\n";
  print "<font size=\"4\"><b>CGI Script Error</b></font><p>\n";
  print "<font size=\"2\">\n";

  if ($message) {
    print $message;
  }
  print "<p>";

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
  if ($CGI::VERSION) {
    print "<tr>\n";
    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>CGI.pm Version</b></font></td>\n";
    print "<td><font face=\"Verdana\" size=\"2\">$CGI::VERSION</font></td>\n";
    print "</tr>\n";
  }
  print "</table><p>\n";

  if (defined %SD::QUERY) {
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

  print "<font size=\"4\"><b>Environment Variables</b></font><p>\n";
  print "<table cellpadding=\"0\" cellspacing=\"0\">\n";
  foreach $key (sort keys %ENV) {
    print "<tr>\n";
    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>$key</b></font></td>\n";
    print "<td><font face=\"Verdana\" size=\"2\">".$ENV{$key}."</font></td>\n";
    print "</tr>\n";
  }
  print "</table><p>\n";

  print "<font size=\"4\"><b>\@INC Contents</b></font><p>\n";
  print "<ul>\n";
  foreach $INC (@INC) {
    print "<li>$INC<br>\n";
  }
  print "</ul><p>\n";
  print "</font>\n";
  print "</font>\n";
  print "</body>\n";
  print "</html>\n";

  exit;
}

1;