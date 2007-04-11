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
# CreateTicket.pm.pl -> CreateTicket module                                   #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CreateTicket;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Mail.pm.pl";

use File::Copy;
use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/CreateTicket.pm.pl";

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

  &Authenticate::SD(DB => $in{'DB'}, REQUIRE_AUTH => $GENERAL->{'REQUIRE_REGISTRATION'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;

  $INPUT{'CATEGORIES'} = $Categories;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CreateTicket->new();

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

  &Authenticate::SD(DB => $in{'DB'}, REQUIRE_AUTH => $GENERAL->{'REQUIRE_REGISTRATION'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "CATEGORY"     , required => 1              },
    { name => "PRIORITY"     , required => 1              },
    { name => "SEVERITY"     , required => 1              },
    { name => "STATUS"       , required => 1              },
    { name => "MESSAGE"      , required => 1              },
    { name => "GUEST_NAME"   , required => 0, size => 128 },
    { name => "EMAIL"        , required => 0, size => 128 }
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

  unless ($SD::USER{'ACCOUNT'}->{'USERNAME'}) {
    if ($RECORD{'EMAIL'} eq "") {
      push(@Error, "MISSING-EMAIL");
    }
  }

  my $Filename = $SD::CGI->param('FORM_ATTACHMENT');
  my $TempFile;
  if ($Filename) {
    $TempFile = $SD::CGI->tmpFileName($Filename);
    my @filename = split(/(\\|\/)/, $Filename);
    $Filename = $filename[$#filename];
    
    my $found;
    foreach my $ext (@{ $GENERAL->{'ATTACHMENT_EXTS'} }) {
      $found = 1 and last if ($Filename =~ /\.$ext$/i);
    }
    if ($found && (-s $TempFile) <= ($GENERAL->{'MAX_ATTACHMENT_SIZE'} * 1024)) {
      $RECORD{'ATTACHMENTS'} = $Filename;
    } else {
      push(@Error, "INVALID-ATTACHMENT");
    }
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Inserting data...                                                    #

  if ($SD::USER{'ACCOUNT'}->{'USERNAME'}) {
    $RECORD{'AUTHOR'}        = $SD::USER{'ACCOUNT'}->{'USERNAME'};
    $RECORD{'EMAIL'}         = $SD::USER{'ACCOUNT'}->{'EMAIL'};
    $RECORD{'GUEST_NAME'}    = "";
  }

  $RECORD{'AUTHOR_TYPE'}     = "USER";
  $RECORD{'DELIVERY_METHOD'} = "CP-USER";
  $RECORD{'PRIVATE'}         = 0;
  $RECORD{'CREATE_SECOND'}   = time;
  $RECORD{'CREATE_DATE'}     = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}     = &Standard::ConvertEpochToTime($RECORD{'CREATE_TIME'});
  $RECORD{'UPDATE_SECOND'}   = $RECORD{'CREATE_SECOND'};
  $RECORD{'UPDATE_DATE'}     = $RECORD{'CREATE_DATE'};
  $RECORD{'UPDATE_TIME'}     = $RECORD{'CREATE_TIME'};
  $RECORD{'NOTES'}           = "1";

  (
    $RECORD{'TID'} = $in{'DB'}->Insert(
      TABLE   => "Tickets",
      VALUES  => \%RECORD
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");
  delete($RECORD{'ID'});

  (
    $RECORD{'NID'} = $in{'DB'}->Insert(
      TABLE   => "Notes",
      VALUES  => \%RECORD
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");
  delete($RECORD{'ID'});

  if ($Filename) {
    mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}")
      || &Error::Error("SD", MESSAGE => "Error creating attachment directory. $!");
    chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}");
    copy($TempFile, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$Filename")
      || &Error::Error("SD", MESSAGE => "Error copying uploaded file. $!");
    chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$Filename");
  }

  $INPUT{'RECORD'} = \%RECORD;

  my $Skin = Skin::CreateTicket->new();
  my $Mail = Mail->new();

  if ($GENERAL->{'NOTIFY_USER_OF_TICKET'}) {
    my %message = $Skin->email(type => "user", input => \%INPUT);
    $Mail->Send(%message) || (print "Error sending email to user. $Mail->{'ERROR'}" and return 1);
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
      my %message = $Skin->email(type => "staff", input => \%INPUT);
      $Mail->Send(%message) || (print "Error sending email to staff member. $Mail->{'ERROR'}" and return 1);
    }
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;