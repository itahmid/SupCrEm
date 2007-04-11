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
# Utilities/ProcessEmail-Pipe.pl -> ProcessEmail-Pipe utility script          #
###############################################################################
# All configuration is performed in the Control Panel. Please do not edit the #
# script directly.                                                            #
###############################################################################
package SD;

BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File SDBM_File) }

BEGIN {
  #############################################################################
  # Change this to the path to SuperDesk if the script fails.                 #
  $SD::PATH = ".."; # < < < < < < < < < < < < < < < < < < < < < < < < < < < < #
  #############################################################################
  # DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                       #
  #############################################################################

  unshift (@INC, "$SD::PATH");
  unshift (@INC, "$SD::PATH/Private");
  unshift (@INC, "$SD::PATH/Private/Variables");
  unshift (@INC, "$SD::PATH/Private/Modules");
  unshift (@INC, "$SD::PATH/Private/Modules/Libraries");
}

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }

BEGIN { %SD::GLOBAL = ("SKIN" => $GENERAL->{'SKIN'}); }

###############################################################################
# Main script: #
################

require "Version.pm.pl";
require "Standard.pm.pl";
require "Mail.pm.pl";

use MIME::Parser;
use Mail::Address;
use File::Copy;
use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/ProcessEmail.pm.pl";

$| = 1;

eval {
  &Main();
} || (print "Couldn't execute your request. $@\n" and exit);

exit;
###############################################################################

###############################################################################
# Main subroutine
sub Main {
  require "Database.$SYSTEM->{'DB_TYPE'}.pm.pl";
  my $DB = new Database;

  &Standard::ProcessPlugins();

  &ProcessEmail(DB => $DB) and return 1;
}

###############################################################################
# ProcessEmail subroutine
sub ProcessEmail {
  my %in = (DB => undef, @_);

  my $Skin    = Skin::ProcessEmail->new();
  my $Mail    = Mail->new();
  my $Parser  = MIME::Parser->new();

  $Parser->ignore_errors(1);
  $Parser->output_to_core(0);
  $Parser->output_dir("$SYSTEM->{'TEMP_PATH'}/Mail");
  
  my $Message = $Parser->parse(\*STDIN);
  my $Head    = $Message->head();
  my @Parts   = $Message->parts();

  my %Message;
  $Message{'TO'}      = $Head->get("To");
  $Message{'FROM'}    = $Head->get("From");
  $Message{'CC'}      = $Head->get("Cc");
  $Message{'SUBJECT'} = $Head->get("Subject");

  while ($Message{'SUBJECT'} =~ /\n$/) {
    chomp($Message{'SUBJECT'});
  }

  my @From = Mail::Address->parse($Message{'FROM'});
  
  if (scalar(@From) >= 1) {
    $Message{'FROM_EMAIL'} = $From[0]->address();
    $Message{'FROM_NAME'}  = $From[0]->name();
  } else {
    print "Couldn't find an email address in the From line.\n";
    return 1;
  }
  
  my (@Body, @Attachments);

  my $ParseEntity;
     $ParseEntity = eval {
    sub {
      my $entity = shift;
      
      my @parts = $entity->parts();
      if (scalar(@parts) >= 1) {
        foreach my $subpart (@parts) {
          &$ParseEntity($subpart);
        }
      } else {
        my $head = $entity->head();
        my $body = $entity->bodyhandle();
        
        if ($entity->effective_type() eq "text/plain" && $head->get("Content-Disposition") !~ /attachment/i) {
          my $io = $body->open("r");
          while (my $line = $io->getline()) {
            push(@Body, $line);
          }
          $io->close();
          $entity->purge();
        } else {
          my $filename = $body->path();
             $filename =~ s/^$SYSTEM->{'TEMP_PATH'}\/Mail\///;
          push(@Attachments, $filename);
        }
      }
    }
  };

  if (scalar(@Parts) < 1) {
    my $io = $Message->open("r");
    while (my $line = $io->getline()) {
      push(@Body, $line);
    }
    $io->close();
  } else {  
    foreach my $part (@Parts) {
      &$ParseEntity($part);
    }
  }

  foreach my $line (@Body) {
    last if ($line =~ /Original Message/i && $GENERAL->{'REMOVE_ORIGINAL_MESSAGE'});
    $Message{'BODY'} .= $line;
  }

  while ($Message{'BODY'} =~ /\n$/) {
    chomp($Message{'BODY'});
  }

  $Message{'BODY'} = join("", @Body) unless ($Message{'BODY'});

  my %INPUT;
  $INPUT{'MESSAGE'}     = \%Message;
  $INPUT{'ATTACHMENTS'} = \@Attachments;

  my ($Accounts, $AccountsIndex) = $in{'DB'}->Query(TABLE => "UserAccounts");
  my @Accounts;
  foreach my $account (@{ $Accounts }) {
    my $metaemail = quotemeta("|".$Message{'FROM_EMAIL'}."|");
    push(@Accounts, $account) if ($account->{'EMAIL'} eq $Message{'FROM_EMAIL'} || $account->{'OTHER_EMAILS'} =~ /$metaemail/i);
  }

  if (scalar(@Accounts) >= 1) {
    $INPUT{'ACCOUNT'} = $Accounts[0];
  } elsif ($GENERAL->{'REQUIRE_REGISTRATION'}) {
    my %message = $Skin->error(error => "INVALID-FROM", input => \%INPUT);
    $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
    return 1;
  }

  if ($Message{'SUBJECT'} eq "") {
    my %message = $Skin->error(error => "MISSING-SUBJECT", input => \%INPUT);
    $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
    return 1;
  }

  if ($Message{'SUBJECT'} =~ /\[SD\-(.*)\]/) {
    $Message{'TICKET_ID'} = $1;
    &NewNote(DB => $in{'DB'}, INPUT => \%INPUT) and return 1;
  } else {
    &NewTicket(DB => $in{'DB'}, INPUT => \%INPUT) and return 1;
  }
}

###############################################################################
# NewNote subroutine
sub NewNote {
  my %in = (DB => undef, INPUT => undef, @_);

  my $Skin    = Skin::ProcessEmail->new();
  my $Mail    = Mail->new();
  my %INPUT   = %{ $in{'INPUT'} };
  my %Message = %{ $INPUT{'MESSAGE'} };

  my $ticket = $in{'DB'}->BinarySelect(
    TABLE   => "Tickets",
    KEY     => $Message{'TICKET_ID'}
  );
  if ($ticket) {
    $INPUT{'TICKET'} = $ticket;
  } else {
    my %message = $Skin->error(error => "INVALID-TICKET_ID", input => \%INPUT);
    $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
    return 1;
  }
    
  if ($ticket->{'AUTHOR'}) {
    if (
      ($INPUT{'ACCOUNT'} && $INPUT{'ACCOUNT'}->{'USERNAME'} ne $ticket->{'AUTHOR'}) ||
      (!$INPUT{'ACCOUNT'})
    ) {
      my %message = $Skin->error(error => "INVALID-ACCOUNT", input => \%INPUT);
      $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
      return 1;
    }
  } else {
    if ($INPUT{'ACCOUNT'}) {
      my $metaemail = quotemeta($ticket->{'EMAIL'});
      if ($INPUT{'ACCOUNT'}->{'EMAIL'} eq $ticket->{'EMAIL'} || $INPUT{'ACCOUNT'}->{'OTHER_EMAILS'} =~ /\|$metaemail\|/i) {
        (
          $in{'DB'}->Update(
            TABLE   => "Tickets",
            VALUES  => {
              AUTHOR      => $INPUT{'ACCOUNT'}->{'USERNAME'},
              GUEST_NAME  => ""
            },
            KEY     => $ticket->{'ID'}
          )
        ) || (print "Error inserting record into database. $in{'DB'}->{'ERROR'}" and return 1);
        $ticket->{'AUTHOR'} = $INPUT{'ACCOUNT'}->{'USERNAME'};
        $ticket->{'GUEST_NAME'} = "";
      } else {
        my %message = $Skin->error(error => "INVALID-ACCOUNT", input => \%INPUT);
        $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
        return 1;
      }
    } elsif ($Message{'FROM_EMAIL'} ne $ticket->{'EMAIL'}) {
      my %message = $Skin->error(error => "INVALID-EMAIL", input => \%INPUT);
      $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
      return 1;
    }
  }
    
  if ($ticket->{'STATUS'} == 70) {
    my %message = $Skin->error(error => "TICKET-CLOSED", input => \%INPUT);
    $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
    return 1;
  }
    
  my %RECORD;
  $RECORD{'TID'}             = $ticket->{'ID'};

  $RECORD{'SUBJECT'}         = $Message{'SUBJECT'};
  $RECORD{'SUBJECT'}         =~ s/Re\:?//ig;
  $RECORD{'SUBJECT'}         =~ s/\[SD\-(.*)\]//;
  
  while ($RECORD{'SUBJECT'} =~ /^ /) {
    $RECORD{'SUBJECT'} =~ s/^ //;
  }
    
  $RECORD{'MESSAGE'}         = $Message{'BODY'};
  $RECORD{'AUTHOR'}          = $INPUT{'ACCOUNT'}->{'USERNAME'} if ($INPUT{'ACCOUNT'});
  $RECORD{'AUTHOR_TYPE'}     = "USER";
  $RECORD{'DELIVERY_METHOD'} = "EMAIL";
  $RECORD{'PRIVATE'}         = 0;
  $RECORD{'CREATE_SECOND'}   = time;
  $RECORD{'CREATE_DATE'}     = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}     = &Standard::ConvertEpochToTime($RECORD{'CREATE_SECOND'});
  $RECORD{'UPDATE_SECOND'}   = $RECORD{'CREATE_SECOND'};
  $RECORD{'UPDATE_DATE'}     = $RECORD{'CREATE_DATE'};
  $RECORD{'UPDATE_TIME'}     = $RECORD{'CREATE_TIME'};

  my (@ActualAttachments, $html);
  foreach my $attachment (@{ $INPUT{'ATTACHMENTS'} }) {
    if ($attachment =~ /msg\-.*\-.*\.html/ && !$html) {
      if ($GENERAL->{'SAVE_HTML_ATTACHMENTS'}) {
        push(@ActualAttachments, "message.html");
        $html = 1;
      }
    } elsif ($GENERAL->{'SAVE_OTHER_ATTACHMENTS'}) {
      my $found;
      foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
        $found = 1 and last if ($attachment =~ /\.$ext$/i);
      }
      if ($found && (-s "$SYSTEM->{'TEMP_PATH'}/Mail/$attachment") <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
        if ($attachment =~ /^message\.html$/i) {
          push(@ActualAttachments, "message-1.html");
        } else {
          push(@ActualAttachments, $attachment);
        }
      }      
    }
  }
  
  $RECORD{'ATTACHMENTS'}     = join(",", @ActualAttachments);
  
  (
    $RECORD{'NID'} = $in{'DB'}->Insert(
      TABLE   => "Notes",
      VALUES  => \%RECORD
    )
  ) || (print "Error inserting record into database. $in{'DB'}->{'ERROR'}" and return 1);

  $INPUT{'RECORD'} = \%RECORD;

  if ($RECORD{'ATTACHMENTS'}) {
    mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}") || (print "Error creating note's attachment directory. $in{'DB'}->{'ERROR'}" and return 1);
    chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}");
    $html = "";
    foreach my $attachment (@{ $INPUT{'ATTACHMENTS'} }) {
      if ($attachment =~ /msg\-.*\-.*\.html/ && !$html) {
        if ($GENERAL->{'SAVE_HTML_ATTACHMENTS'}) {
          copy("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message.html") || (print "Error copying attachment. $!" and return 1);
          chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message.html");
          $html = 1;
        }
      } elsif ($GENERAL->{'SAVE_OTHER_ATTACHMENTS'}) {
        my $found;
        foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
          $found = 1 and last if ($attachment =~ /\.$ext$/i);
        }
        if ($found && (-s "$SYSTEM->{'TEMP_PATH'}/Mail/$attachment") <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
          if ($attachment =~ /^message\.html$/i) {
            copy("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message-1.html") || (print "Error copying attachment. $!" and return 1);
            chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message-1.html");
          } else {
            copy("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$attachment") || (print "Error copying attachment. $!" and return 1);
            chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$attachment");
          }
        }
      }
      unlink("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment");
    }
  }

  (
    $in{'DB'}->Update(
      TABLE   => "Tickets",
      VALUES  => {
        UPDATE_SECOND   => $RECORD{'CREATE_SECOND'},
        UPDATE_DATE     => $RECORD{'CREATE_DATE'},
        UPDATE_TIME     => $RECORD{'CREATE_TIME'},
        NOTES           => "++\${NOTES}"
      },
      KEY     => $RECORD{'TID'}
    )
  ) || (print "Error updating record in database. $in{'DB'}->{'ERROR'}" and return 1);

  $INPUT{'CATEGORY'} = $in{'DB'}->BinarySelect(
    TABLE   => "Categories",
    KEY     => $ticket->{'CATEGORY'}
  );

  if ($GENERAL->{'NOTIFY_USER_OF_NOTE'}) {
    my %message = $Skin->note(type => "user", input => \%INPUT);
    unless ($GENERAL->{'EMAIL_ADDRESSES'}->{$message{'TO'}}){
      $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}" and return 1);
    }
  }
    
  if ($ticket->{'OWNED_BY'}) {
    my $account = $in{'DB'}->BinarySelect(
      TABLE   => "StaffAccounts",
      KEY     => $ticket->{'OWNED_BY'}
    );
    if ($account->{'NOTIFY_NEW_NOTES_OWNED'}) {
      $INPUT{'STAFF_ACCOUNT'} = $account;
      my %message = $Skin->note(type => "ownedstaff", input => \%INPUT);
      $Mail->Send(%message) || (print "Error sending email to staff member. $Mail->{'ERROR'}" and return 1);
    }
  } else {
    my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
      TABLE   => "StaffAccounts",
      WHERE   => {
        NOTIFY_NEW_NOTES_UNOWNED  => ["1"]
      },
      MATCH   => "ALL"
    );
    if (scalar(@{ $StaffAccounts }) >= 1) {
      foreach my $account (@{ $StaffAccounts }) {
        $INPUT{'STAFF_ACCOUNT'} = $account;
        my %message = $Skin->note(type => "unownedstaff", input => \%INPUT);
        $Mail->Send(%message) || (print "Error sending email to staff member. $Mail->{'ERROR'}" and return 1);
      }
    }
  }

  return 1;
}

###############################################################################
# NewTicket subroutine
sub NewTicket {
  my %in = (DB => undef, INPUT => undef, @_);

  my $Skin    = Skin::ProcessEmail->new();
  my $Mail    = Mail->new();
  my %INPUT   = %{ $in{'INPUT'} };
  my %Message = %{ $INPUT{'MESSAGE'} };

  my @To = Mail::Address->parse($Message{'TO'});
  my @Cc = Mail::Address->parse($Message{'CC'});

  my $Category;
  foreach my $address (@To, @Cc) {
    if ($GENERAL->{'EMAIL_ADDRESSES'}->{$address->address()}) {
      $Category = $GENERAL->{'EMAIL_ADDRESSES'}->{$address->address()};
    }
  }
  unless ($Category) {
    my %message = $Skin->error(error => "INVALID-TO", input => \%INPUT);
    $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}");
    return 1;
  }
    
  $INPUT{'CATEGORY'} = $in{'DB'}->BinarySelect(
    TABLE   => "Categories",
    KEY     => $Category
  );

  my %RECORD;
    
  $RECORD{'SUBJECT'}         = $Message{'SUBJECT'};
  $RECORD{'SUBJECT'}         =~ s/Re\:?//ig;
  $RECORD{'SUBJECT'}         =~ s/\[SD\-(.*)\]//;

  while ($RECORD{'SUBJECT'} =~ /^ /) {
    $RECORD{'SUBJECT'} =~ s/^ //;
  }
    
  $RECORD{'CATEGORY'}        = $INPUT{'CATEGORY'}->{'ID'};
  $RECORD{'MESSAGE'}         = $Message{'BODY'};
  $RECORD{'AUTHOR'}          = $INPUT{'ACCOUNT'}->{'USERNAME'} if ($INPUT{'ACCOUNT'});
  $RECORD{'GUEST_NAME'}      = $Message{'FROM_NAME'} if (!$INPUT{'ACCOUNT'} && $Message{'FROM_NAME'});
  $RECORD{'AUTHOR_TYPE'}     = "USER";
  $RECORD{'EMAIL'}           = $Message{'FROM_EMAIL'};
  $RECORD{'PRIORITY'}        = $GENERAL->{'DEFAULT_PRIORITY'};
  $RECORD{'SEVERITY'}        = $GENERAL->{'DEFAULT_SEVERITY'};
  $RECORD{'STATUS'}          = $GENERAL->{'DEFAULT_STATUS'};
  $RECORD{'DELIVERY_METHOD'} = "EMAIL";
  $RECORD{'PRIVATE'}         = 0;
  $RECORD{'CREATE_SECOND'}   = time;
  $RECORD{'CREATE_DATE'}     = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}     = &Standard::ConvertEpochToTime($RECORD{'CREATE_SECOND'});
  $RECORD{'UPDATE_SECOND'}   = $RECORD{'CREATE_SECOND'};
  $RECORD{'UPDATE_DATE'}     = $RECORD{'CREATE_DATE'};
  $RECORD{'UPDATE_TIME'}     = $RECORD{'CREATE_TIME'};
  $RECORD{'NOTES'}           = "1";

  my (@ActualAttachments, $html);
  foreach my $attachment (@{ $INPUT{'ATTACHMENTS'} }) {
    if ($attachment =~ /msg\-.*\-.*\.html/ && !$html) {
      if ($GENERAL->{'SAVE_HTML_ATTACHMENTS'}) {
        push(@ActualAttachments, "message.html");
        $html = 1;
      }
    } elsif ($GENERAL->{'SAVE_OTHER_ATTACHMENTS'}) {
      my $found;
      foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
        $found = 1 and last if ($attachment =~ /\.$ext$/i);
      }
      if ($found && (-s "$SYSTEM->{'TEMP_PATH'}/Mail/$attachment") <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
        if ($attachment =~ /^message\.html$/i) {
          push(@ActualAttachments, "message-1.html");
        } else {
          push(@ActualAttachments, $attachment);
        }
      }
    }
  }
  
  $RECORD{'ATTACHMENTS'}     = join(",", @ActualAttachments);

  (
    $RECORD{'TID'} = $in{'DB'}->Insert(
      TABLE   => "Tickets",
      VALUES  => \%RECORD
    )
  ) || (print "Error inserting record into database. $in{'DB'}->{'ERROR'}" and return 1);
  delete($RECORD{'ID'});
    
  (
    $RECORD{'NID'} = $in{'DB'}->Insert(
      TABLE   => "Notes",
      VALUES  => \%RECORD
    )
  ) || (print "Error inserting record into database. $in{'DB'}->{'ERROR'}" and return 1);
  delete($RECORD{'ID'});

  $INPUT{'RECORD'} = \%RECORD;

  if ($RECORD{'ATTACHMENTS'}) {
    mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}") || (print "Error creating note's attachment directory. $in{'DB'}->{'ERROR'}" and return 1);
    chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}");
    $html = "";
    foreach my $attachment (@{ $INPUT{'ATTACHMENTS'} }) {
      if ($attachment =~ /msg\-.*\-.*\.html/ && !$html) {
        if ($GENERAL->{'SAVE_HTML_ATTACHMENTS'}) {
          copy("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message.html") || (print "Error copying attachment. $!" and return 1);
          chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message.html");
          $html = 1;
        }
      } elsif ($GENERAL->{'SAVE_OTHER_ATTACHMENTS'}) {
        my $found;
        foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
          $found = 1 and last if ($attachment =~ /\.$ext$/i);
        }
        if ($found && (-s "$SYSTEM->{'TEMP_PATH'}/Mail/$attachment") <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
          if ($attachment =~ /^message\.html$/i) {
            copy("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message-1.html") || (print "Error copying attachment. $!" and return 1);
            chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/message-1.html");
          } else {
            copy("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$attachment") || (print "Error copying attachment. $!" and return 1);
            chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$attachment");
          }
        }
      }
      unlink("$SYSTEM->{'TEMP_PATH'}/Mail/$attachment");
    }
  }

  if ($GENERAL->{'NOTIFY_USER_OF_TICKET'}) {
    my %message = $Skin->ticket(type => "user", input => \%INPUT);
    unless ($GENERAL->{'EMAIL_ADDRESSES'}->{$message{'TO'}}){
      $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}" and return 1);
    }
  }
    
  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    WHERE   => {
      NOTIFY_NEW_TICKETS  => ["1"]
    },
    MATCH   => "ALL"
  );
  if (scalar(@{ $StaffAccounts }) >= 1) {
    foreach my $account (@{ $StaffAccounts }) {
      $INPUT{'STAFF_ACCOUNT'} = $account;
      my %message = $Skin->ticket(type => "staff", input => \%INPUT);
      $Mail->Send(%message) || (print "Error sending email to staff member. $Mail->{'ERROR'}" and return 1);
    }
  }

  return 1;
}

1;