###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# General.pm.pl -> General variable module                                    #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package General;

require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw(@EXPORT_OK);
@EXPORT_OK = qw($GENERAL);

use strict;
use vars qw($GENERAL);

$GENERAL = {
  "SITE_TITLE"                  => "SuperDesk",
  "SITE_URL"                    => "http://www.plasmapulse.com/?sc=SuperDesk",
  "DESK_TITLE"                  => "SuperDesk",
  "DESK_DESCRIPTION"            => "Welcome to our help desk.",

  "CONTACT_EMAIL"               => "webmaster\@plasmapulse.com",
  "ADMIN_EMAIL"                 => "webmaster\@plasmapulse.com",

  "SKIN"                        => "Default",

  "MAIL_FUNCTIONS"              => "1",
  "NOTIFY_USER_OF_TICKET"       => "1",
  "NOTIFY_USER_OF_NOTE"         => "1",
  "REQUIRE_REGISTRATION"        => "0",
  
  "SAVE_HTML_ATTACHMENTS"       => "1",
  "SAVE_OTHER_ATTACHMENTS"      => "1",
  "USER_ATTACHMENTS"            => "1",
  "ATTACHMENT_EXTS"             => ["gif","jpg","jpeg","zip","bmp","png","txt","htm","html"],
  "MAX_ATTACHMENT_SIZE"         => "2048",
  "SHOW_HTML_MESSAGE"           => "1",
  "REMOVE_ORIGINAL_MESSAGE"     => "0",
  
  "HTML_IN_ADMIN_EMAILS"        => "0",
  "HTML_IN_USER_EMAILS"         => "0",

  "DATE_FORMAT"                 => "US",
  "TIME_FORMAT"                 => "12",

  "ALLOW_SUPPORT_CREATE_USERS"  => "1",
  "ALLOW_SUPPORT_MODIFY_USERS"  => "1",
  "ALLOW_SUPPORT_REMOVE_USERS"  => "1",
  
  "DEFAULT_PRIORITY"            => "30",
  "DEFAULT_SEVERITY"            => "30",
  "DEFAULT_STATUS"              => "30",
  
  "TICKETS_PER_PAGE"            => "10",
  
  "USER_LEVELS"                 => {
    "30"  => "Registered Member",
    "40"  => "License Holder",
    "50"  => "Beta Tester",
    "60"  => "Corporate Customer"
  },
  
  "PRIORITIES"                  => {
    "30"  => "Low",
    "40"  => "Medium",
    "50"  => "High",
    "60"  => "Very High"
  },
  
  "SEVERITIES"                  => {
    "30"  => "Low",
    "40"  => "Medium",
    "50"  => "High",
    "60"  => "Very High"
  },
  
  "STATUS"                      => {
    "30"  => "Open",
    "40"  => "Unresolved",
    "50"  => "On Hold",
    "60"  => "Resolved",
    "70"  => "Closed"
  },
  
  "EMAIL_ADDRESSES"             => { }  
};

1;
