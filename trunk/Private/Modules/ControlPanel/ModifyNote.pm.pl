###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/ModifyNote.pm.pl -> ModifyNote module                          #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::ModifyNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Copy;

use strict;

require "ControlPanel/Output/ModifyNote.pm.pl";

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

  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #
  
  if (!$SD::QUERY{'NID'}) {
    &Error::Error("CP", MESSAGE => "You didn't specify a Note ID (NID)");
  }

  my $Note = $in{'DB'}->BinarySelect(
    TABLE   => "Notes",
    KEY     => $SD::QUERY{'NID'}
  );
  unless ($Note) {
    &Error::Error("CP", MESSAGE => "The Note ID (NID) you specified is invalid");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE   => "Tickets",
    KEY     => $Note->{'TID'}
  );

  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $found;
    foreach my $category (@categories) {
      $found = 1 and last if ($category == $Ticket->{'CATEGORY'});
    }
    unless ($found) {
      &Error::Error("CP", MESSAGE => "You have insufficient rights to use this feature");
    }
  }

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      TID => [$Ticket->{'ID'}]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "A-Z"
  );

  my %INPUT;

  $INPUT{'NOTE'} = $Note;
  $INPUT{'TICKET'} = $Ticket;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;
  $INPUT{'FIRST_NOTE'} = 1 if ($Notes->[0]->{'ID'} == $SD::QUERY{'NID'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyNote->new();

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

  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'NID'}) {
    &Error::Error("CP", MESSAGE => "You didn't specify a Note ID (NID)");
  }

  my $Note = $in{'DB'}->BinarySelect(
    TABLE   => "Notes",
    KEY     => $SD::QUERY{'NID'}
  );
  unless ($Note) {
    &Error::Error("CP", MESSAGE => "The Note ID (NID) you specified is invalid");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE   => "Tickets",
    KEY     => $Note->{'TID'}
  );

  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      TID => [$Ticket->{'ID'}]
    },
    MATCH   => "ALL",
    SORT    => "CREATE_SECOND",
    BY      => "A-Z"
  );

  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $found;
    foreach my $category (@categories) {
      $found = 1 and last if ($category == $Ticket->{'CATEGORY'});
    }
    unless ($found) {
      &Error::Error("CP", MESSAGE => "You have insufficient rights to use this feature");
    }
  }

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "MESSAGE"      , required => 1              },
    { name => "AUTHOR"       , required => 0              },
    { name => "PRIVATE"      , required => 0              }
  );

  my (%RECORD, %INPUT, @Error);

  foreach my $field (@Fields) {
    if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}} eq "") {
      push(@Error, "MISSING-".$field->{'name'});
    } elsif ($field->{'size'} && $SD::QUERY{'FORM_'.$field->{'name'}} ne "" && length($SD::QUERY{'FORM_'.$field->{'name'}}) > $field->{'size'}) {
      push(@Error, "TOOLONG-".$field->{'name'});
    } else {
      $RECORD{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
    }
  }

  if ($Notes->[0]->{'ID'} == $SD::QUERY{'NID'}) {
    $RECORD{'AUTHOR'} = $Note->{'AUTHOR'};
    $RECORD{'AUTHOR_TYPE'} = "USER";
  } elsif ($RECORD{'AUTHOR'} ne "") {
    if ($RECORD{'AUTHOR'} eq "[TICKET-AUTHOR]") {
      $RECORD{'AUTHOR'} = $Ticket->{'AUTHOR'};
      $RECORD{'AUTHOR_TYPE'} = "USER";
    } else {
      my $staff = $in{'DB'}->BinarySelect(
        TABLE   => "StaffAccounts",
        KEY     => $RECORD{'AUTHOR'}
      );
      if ($staff) {
        $RECORD{'AUTHOR_TYPE'} = "STAFF";
        $INPUT{'STAFF_ACCOUNT'} = $staff;
      } else {
        push(@Error, "INVALID-AUTHOR");
      }
    }
  } else {
    push(@Error, "MISSING-AUTHOR");
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  $RECORD{'PRIVATE'}     ||= 0;
  $RECORD{'PRIVATE'}       = 0 if ($SD::QUERY{'FORM_NOTE_AUTHOR'} eq "[TICKET-AUTHOR]");
  $RECORD{'UPDATE_SECOND'} = time;
  $RECORD{'UPDATE_DATE'}   = &Standard::ConvertEpochToDate($RECORD{'UPDATE_SECOND'});
  $RECORD{'UPDATE_TIME'}   = &Standard::ConvertEpochToTime($RECORD{'UPDATE_SECOND'});

  my @Attachments = $SD::CGI->param('FORM_ATTACHMENT_DELETE');
  foreach my $attachment (@Attachments) {
    if (-e "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$attachment") {
      unlink("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$attachment");
    }
  }

  my $Filename = $SD::CGI->param('FORM_ATTACHMENT_UPLOAD');
  if ($Filename) {
    my $tempfile = $SD::CGI->tmpFileName($Filename);
    my @filename = split(/(\\|\/)/, $Filename);
    $Filename = $filename[$#filename];
    if (-e "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$Filename") {
      my ($name, $extension) = split(/\./, $Filename);
      my $count = 1;
      while (-e "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$name-$count.$extension") {
        $count++;
      }
      $Filename = $name."-".$count.".".$extension;
    }
    unless (-d "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}") {
      mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}")
        || &Error::Error("CP", MESSAGE => "Error creating attachment directory. $!");
      chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}");
    }
    copy($tempfile, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$Filename")
      || &Error::Error("CP", MESSAGE => "Error copying uploaded file. $!");
    chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$Filename");
  }

  @Attachments = ();
  opendir(DIR, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}");
  foreach my $file (readdir(DIR)) {
    push(@Attachments, $file) if (-f "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$file");
  }
  closedir(DIR);
  
  $RECORD{'ATTACHMENTS'} = join(",", @Attachments);

  (
    $in{'DB'}->Update(
      TABLE   => "Notes",
      VALUES  => \%RECORD,
      KEY     => $SD::QUERY{'NID'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

  (
    $in{'DB'}->Update(
      TABLE   => "Tickets",
      VALUES  => {
        UPDATE_SECOND => $RECORD{'UPDATE_SECOND'},
        UPDATE_DATE   => $RECORD{'UPDATE_DATE'},
        UPDATE_TIME   => $RECORD{'UPDATE_TIME'}
      },
      KEY     => $Note->{'TID'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

  my $Category = $in{'DB'}->BinarySelect(
    TABLE   => "Categories",
    KEY     => $Ticket->{'CATEGORY'}
  );

  if ($Ticket->{'AUTHOR'}) {
    my $UserAccount = $in{'DB'}->BinarySelect(
      TABLE   => "UserAccounts",
      KEY     => $Ticket->{'AUTHOR'}
    );
    $INPUT{'USER_ACCOUNT'} = $UserAccount;
  }
  
  $INPUT{'NOTE'} = $Note;
  $INPUT{'TICKET'} = $Ticket;
  $INPUT{'CATEGORY'} = $Category;
  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyNote->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;