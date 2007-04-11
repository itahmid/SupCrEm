###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/CreateTicket.pm.pl -> CreateTicket module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::CreateTicket;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Copy;
use strict;

require "ControlPanel/Output/CreateTicket.pm.pl";

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
  # Getting data...                                                      #

  my %Where;
  
  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    $Where{'CATEGORY'} = \@categories;
  }

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => \%Where,
    MATCH   => "ANY",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateTicket->new();

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
  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*" && $SD::QUERY{'FORM_CATEGORY'}) {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $found;
    foreach my $category (@categories) {
      $found = 1 and last if ($SD::QUERY{'FORM_CATEGORY'} == $category);
    }
    unless ($found) {
      $self->show(DB => $in{'DB'}, ERROR => "ACCESS-DENIED");
      return 1;
    }
  }

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "CATEGORY"     , required => 1              },
    { name => "AUTHOR"       , required => 0              },
    { name => "GUEST_NAME"   , required => 0, size => 128 },
    { name => "EMAIL"        , required => 0, size => 128 },
    { name => "PRIORITY"     , required => 1              },
    { name => "SEVERITY"     , required => 1              },
    { name => "STATUS"       , required => 1              },
    { name => "OWNED_BY"     , required => 0              },
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

  if ($SD::QUERY{'FORM_AUTHOR_TYPE'} eq "REG") {
    if ($RECORD{'AUTHOR'}) {
      my $author = $in{'DB'}->BinarySelect(
        TABLE   => "UserAccounts",
        KEY     => $RECORD{'AUTHOR'}
      );
      if ($author) {
        $INPUT{'AUTHOR'}      = $author;
        $RECORD{'EMAIL'}      = $author->{'EMAIL'};
        $RECORD{'GUEST_NAME'} = "";
      } else {
        push(@Error, "INVALID-AUTHOR");
      }
    } else {
      push(@Error, "MISSING-AUTHOR");
    }
  } elsif ($SD::QUERY{'FORM_AUTHOR_TYPE'} eq "GUEST") {
    $RECORD{'AUTHOR'} = "";
    push(@Error, "MISSING-AUTHOR") if ($RECORD{'EMAIL'} eq "");
  } else {
    push(@Error, "MISSING-AUTHOR");
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

  if ($RECORD{'OWNED_BY'}) {
    if ($SD::ADMIN{'LEVEL'} != 100 && $RECORD{'OWNED_BY'} ne $SD::ADMIN{'USERNAME'}) {
      push(@Error, "INVALID-OWNED_BY");
    } else {
      my $staff = $in{'DB'}->BinarySelect(
        TABLE   => "StaffAccounts",
        KEY     => $RECORD{'OWNED_BY'}
      );
      if ($staff) {
        if ($RECORD{'CATEGORY'} && $staff->{'CATEGORIES'} ne "*" && $staff->{'LEVEL'} != 100) {
          my @categories = split(/,/, $staff->{'CATEGORIES'});
          my $found;
          foreach my $category (@categories) {
            $found = 1 and last if ($category == $RECORD{'CATEGORY'});
          }
          unless ($found) {
            push(@Error, "INVALID-OWNED_BY");
          }
        }
        $INPUT{'STAFF'} = $staff;
      } else {
        push(@Error, "INVALID-OWNED_BY");
      }
    }
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Inserting data...                                                    #

  $RECORD{'DELIVERY_METHOD'} = "CP-STAFF";
  $RECORD{'PRIVATE'}         = 0;
  $RECORD{'CREATE_SECOND'}   = time;
  $RECORD{'CREATE_DATE'}     = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}     = &Standard::ConvertEpochToTime($RECORD{'CREATE_TIME'});
  $RECORD{'UPDATE_SECOND'}   = $RECORD{'CREATE_SECOND'};
  $RECORD{'UPDATE_DATE'}     = $RECORD{'CREATE_DATE'};
  $RECORD{'UPDATE_TIME'}     = $RECORD{'CREATE_TIME'};
  $RECORD{'NOTES'}           = "1";
  
  $RECORD{'AUTHOR_TYPE'}     = "USER";

  my $Filename = $SD::CGI->param('FORM_ATTACHMENT');
  my $TempFile;
  if ($Filename) {
    $TempFile = $SD::CGI->tmpFileName($Filename);
    my @filename = split(/(\\|\/)/, $Filename);
    $Filename = $filename[$#filename];
    $RECORD{'ATTACHMENTS'} = $Filename;
  }

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
      || &Error::Error("CP", MESSAGE => "Error creating attachment directory. $!");
    chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}");
    copy($TempFile, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$Filename")
      || &Error::Error("CP", MESSAGE => "Error copying uploaded file. $!");
    chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$RECORD{'NID'}/$Filename");
  }

  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateTicket->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;