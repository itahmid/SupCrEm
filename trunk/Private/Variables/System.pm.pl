###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# System.pm.pl -> System variable module                                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package System;

require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw(@EXPORT_OK);
@EXPORT_OK = qw($SYSTEM);

use strict;
use vars qw($SYSTEM);

$SYSTEM = {
  "INSTALLED"                 => "0",

  "DB_PATH"                   => "$SD::PATH/Private/Database",
  "TEMP_PATH"                 => "$SD::PATH/Private/Database/Temp",
  "LOGS_PATH"                 => "$SD::PATH/Private/Logs",
  "BACKUP_PATH"               => "$SD::PATH/Private/Backups",
  "CACHE_PATH"                => "$SD::PATH/Private/Database/Temp/Cache",
  "PUBLIC_PATH"               => "$SD::PATH/Public",

  "SCRIPT_URL"                => "",
  "PUBLIC_URL"                => "",

  "DB_TYPE"                   => "dbm",
  "DB_PREFIX"                 => "SD_",
  "DB_HOST"                   => "localhost",
  "DB_PORT"                   => "",
  "DB_NAME"                   => "superdesk",
  "DB_USERNAME"               => "root",
  "DB_PASSWORD"               => "",

  "FLOCK"                     => "0",

  "MAIL_TYPE"                 => "SENDMAIL",
  "SENDMAIL"                  => "/usr/lib/sendmail",
  "SMTP_SERVER"               => "localhost",

  "LOG_ERRORS"                => "1",
  
  "START_TAG"                 => "[%",
  "END_TAG"                   => "%]",

  "LOCALTIME_OFFSET"          => "0",
  
  "SHOW_CGI_ERRORS"           => "1",
  "CACHING"                   => "0"
};

1;
