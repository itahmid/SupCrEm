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
# ModifyTicket.pm.pl -> ModifyTicket module                                   #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package ModifyTicket;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Mail.pm.pl";

use File::Copy;
use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/ModifyTicket.pm.pl";

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# show subroutine
sub show {
  my $self = shift;
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::SD(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  if (!$SD::QUERY{'TID'}) {
    &Error::Error("SD", MESSAGE => "You didn't specify a Ticket ID (TID)");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE => "Tickets",
    KEY   => $SD::QUERY{'TID'}
  );
  unless ($Ticket) {
    &Error::Error("SD", MESSAGE => "The Ticket ID (TID) that you specified is invalid");
  }

  unless ($Ticket->{'AUTHOR'} eq $SD::USER{'ACCOUNT'}->{'USERNAME'}) {
    &Error::Error("SD", MESSAGE => "You are not the author of the specified ticket");
  }

  my $Category = $in{'DB'}->BinarySelect(
    TABLE => "Categories",
    KEY   => $Ticket->{'CATEGORY'}
  );

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      TID     => [$SD::QUERY{'TID'}],
      PRIVATE => ["0"]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "A-Z"
  );

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;

  $INPUT{'TICKET'} = $Ticket;
  $INPUT{'CATEGORY'} = $Category;
  $INPUT{'NOTES'} = $Notes;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;
  $INPUT{'STAFF_ACCOUNTS_IX'} = $StaffAccountsIndex;
  $INPUT{'CATEGORIES'} = $Categories;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::ModifyTicket->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT, error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::SD(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  if (!$SD::QUERY{'TID'}) {
    &Error::Error("SD", MESSAGE => "You didn't specify a Ticket ID (TID)");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE => "Tickets",
    KEY   => $SD::QUERY{'TID'}
  );
  unless ($Ticket) {
    &Error::Error("SD", MESSAGE => "The Ticket ID (TID) that you specified is invalid");
  }

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "CATEGORY"     , required => 1              },
    { name => "PRIORITY"     , required => 1              },
    { name => "SEVERITY"     , required => 1              },
    { name => "STATUS"       , required => 1              }
  );

  my (%RECORD, %INPUT);

  my @Error;
  foreach my $field (@Fields) {
    if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}} eq "") {
      push(@Error, "MISSING-".$field->{'name'});
    } elsif ($field->{'size'} && $SD::QUERY{'FORM_'.$field->{'name'}} ne "" && length($SD::QUERY{'FORM_'.$field->{'name'}}) > $field->{'size'}) {
      push(@Error, "TOOLONG-".$field->{'name'});
    } else {
      $RECORD{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
    }
  }
  
  if ($RECORD{'CATEGORY'}) {
    my $category = $in{'DB'}->BinarySelect(
      TABLE   => "Categories",
      KEY     => $RECORD{'CATEGORY'}
    );
    if ($category) {
      $INPUT{'CATEGORY'} = $category;
    } else {
      push(@Error, "INVALID-CATEGORY");
    }
  }

  my ($Filename, $TempFile, %NOTE);
  if ($SD::QUERY{'FORM_NOTE'}) {
    push(@Error, "MISSING-NOTE_SUBJECT") if ($SD::QUERY{'FORM_NOTE_SUBJECT'} eq "");
    push(@Error, "TOOLONG-NOTE_SUBJECT") if (length($SD::QUERY{'FORM_NOTE_SUBJECT'} > 512));
    push(@Error, "MISSING-NOTE_MESSAGE") if ($SD::QUERY{'FORM_NOTE_MESSAGE'} eq "");

    $Filename = $SD::CGI->param('FORM_NOTE_ATTACHMENT');
    if ($Filename) {
      $TempFile = $SD::CGI->tmpFileName($Filename);
      my @filename = split(/(\\|\/)/, $Filename);
      $Filename = $filename[$#filename];

      my $found;
      foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
        $found = 1 and last if ($Filename =~ /\.$ext$/i);
      }
      if ($found && (-s $TempFile) <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
        $NOTE{'ATTACHMENTS'} = $Filename;
      } else {
        push(@Error, "INVALID-NOTE_ATTACHMENT");
      }
    }
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  $RECORD{'UPDATE_SECOND'} = time;
  $RECORD{'UPDATE_DATE'}   = &Standard::ConvertEpochToDate($RECORD{'UPDATE_SECOND'});
  $RECORD{'UPDATE_TIME'}   = &Standard::ConvertEpochToTime($RECORD{'UPDATE_TIME'});

  $RECORD{'NOTES'}         = $Ticket->{'NOTES'} + 1 if ($SD::QUERY{'FORM_NOTE'});

  (
    $in{'DB'}->Update(
      TABLE   => "Tickets",
      VALUES  => \%RECORD,
      KEY     => $SD::QUERY{'TID'}
    )
  ) || &Error::Error("SD", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

  $INPUT{'RECORD'} = \%RECORD;
  $INPUT{'TICKET'} = $Ticket;

  my $Skin = Skin::ModifyTicket->new();

  if ($SD::QUERY{'FORM_NOTE'}) {
    $NOTE{'TID'}             = $SD::QUERY{'TID'};
    $NOTE{'SUBJECT'}         = $SD::QUERY{'FORM_NOTE_SUBJECT'};
    $NOTE{'MESSAGE'}         = $SD::QUERY{'FORM_NOTE_MESSAGE'};

    $NOTE{'AUTHOR'}          = $Ticket->{'AUTHOR'};
    $NOTE{'AUTHOR_TYPE'}     = "USER";
    $NOTE{'DELIVERY_METHOD'} = "CP-USER";
    $NOTE{'PRIVATE'}         = 0;
    $NOTE{'CREATE_SECOND'}   = time;
    $NOTE{'CREATE_DATE'}     = &Standard::ConvertEpochToDate($NOTE{'CREATE_SECOND'});
    $NOTE{'CREATE_TIME'}     = &Standard::ConvertEpochToTime($NOTE{'CREATE_SECOND'});
    $NOTE{'UPDATE_SECOND'}   = $NOTE{'CREATE_SECOND'};
    $NOTE{'UPDATE_DATE'}     = $NOTE{'CREATE_DATE'};
    $NOTE{'UPDATE_TIME'}     = $NOTE{'CREATE_TIME'};

    (
      $NOTE{'ID'} = $in{'DB'}->Insert(
        TABLE   => "Notes",
        VALUES  => \%NOTE
      )
    ) || &Error::Error("SD", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

    if ($Filename) {
      mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'ID'}")
        || &Error::Error("SD", MESSAGE => "Error creating attachment directory. $!");
      chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'ID'}");
      copy($TempFile, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'ID'}/$Filename")
        || &Error::Error("SD", MESSAGE => "Error copying uploaded file. $!");
      chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'ID'}/$Filename");
    }

    $INPUT{'NOTE_RECORD'} = \%NOTE;

    my $Mail = Mail->new();

    if ($GENERAL->{'NOTIFY_USER_OF_NOTE'}) {
      my %message = $Skin->email(type => "user", input => \%INPUT);
      $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}" and return 1);
    }

    if ($Ticket->{'OWNED_BY'}) {
      my $account = $in{'DB'}->BinarySelect(
        TABLE   => "StaffAccounts",
        KEY     => $Ticket->{'OWNED_BY'}
      );
      if ($account->{'NOTIFY_NEW_NOTES_OWNED'}) {
        $INPUT{'STAFF_ACCOUNT'} = $account;
        my %message = $Skin->email(type => "ownedstaff", input => \%INPUT);
        my $Mail = Mail->new();
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
          my %message = $Skin->email(type => "unownedstaff", input => \%INPUT);
          $Mail->Send(%message) || (print "Error sending email to staff member. $Mail->{'ERROR'}" and return 1);
        }
      }
    }
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;