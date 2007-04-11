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
# ModifyNote.pm.pl -> ModifyNote module                                       #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package ModifyNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Copy;
use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/ModifyNote.pm.pl";

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

  if (!$SD::QUERY{'NID'}) {
    &Error::Error("SD", MESSAGE => "You didn't specify a Note ID (NID)");
  }

  my $Note = $in{'DB'}->BinarySelect(
    TABLE   => "Notes",
    KEY     => $SD::QUERY{'NID'}
  );
  unless ($Note) {
    &Error::Error("SD", MESSAGE => "The Note ID (NID) you specified is invalid");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE   => "Tickets",
    KEY     => $Note->{'TID'}
  );

  unless ($Note->{'AUTHOR'} eq $SD::USER{'ACCOUNT'}->{'USERNAME'}) {
    &Error::Error("SD", MESSAGE => "You are not the author of the specified note");
  }

  my %INPUT;

  $INPUT{'NOTE'} = $Note;
  $INPUT{'TICKET'} = $Ticket;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::ModifyNote->new();

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

  if (!$SD::QUERY{'NID'}) {
    &Error::Error("SD", MESSAGE => "You didn't specify a Note ID (NID)");
  }

  my $Note = $in{'DB'}->BinarySelect(
    TABLE   => "Notes",
    KEY     => $SD::QUERY{'NID'}
  );
  unless ($Note) {
    &Error::Error("SD", MESSAGE => "The Note ID (NID) you specified is invalid");
  }

  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE   => "Tickets",
    KEY     => $Note->{'TID'}
  );

  unless ($Note->{'AUTHOR'} eq $SD::USER{'ACCOUNT'}->{'USERNAME'}) {
    &Error::Error("SD", MESSAGE => "You are not the author of the specified note");
  }

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "MESSAGE"      , required => 1              }
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

  my $Filename = $SD::CGI->param('FORM_ATTACHMENT_UPLOAD');
  my $TempFile;
  if ($Filename) {
    my $TempFile = $SD::CGI->tmpFileName($Filename);
    my @filename = split(/(\\|\/)/, $Filename);
    $Filename = $filename[$#filename];

    my $found;
    foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
      $found = 1 and last if ($Filename =~ /\.$ext$/i);
    }
    if ($found && (-s $TempFile) <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
      if (-e "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$Filename") {
        my ($name, $extension) = split(/\./, $Filename);
        my $count = 1;
        while (-e "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$name-$count.$extension") {
          $count++;
        }
        $Filename = $name."-".$count.".".$extension;
      }
    } else {
      push(@Error, "INVALID-ATTACHMENT");
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

  my @Attachments = $SD::CGI->param('FORM_ATTACHMENT_DELETE');
  foreach my $attachment (@Attachments) {
    if (-e "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$attachment") {
      unlink("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$attachment");
    }
  }

  if ($Filename) {
    unless (-d "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}") {
      mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}")
        || &Error::Error("SD", MESSAGE => "Error creating attachment directory. $!");
      chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}");
    }
    copy($TempFile, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$SD::QUERY{'NID'}/$Filename")
      || &Error::Error("SD", MESSAGE => "Error copying uploaded file. $!");
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
  ) || &Error::Error("SD", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

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
  ) || &Error::Error("SD", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

  my $Category = $in{'DB'}->BinarySelect(
    TABLE   => "Categories",
    KEY     => $Ticket->{'CATEGORY'}
  );

  $INPUT{'NOTE'} = $Note;
  $INPUT{'TICKET'} = $Ticket;
  $INPUT{'CATEGORY'} = $Category;
  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::ModifyNote->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;