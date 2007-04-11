###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/CreateUser.pm.pl -> CreateUser module                          #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::CreateUser;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/CreateUser.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_CREATE_USERS'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateUser->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_CREATE_USERS'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
    { name => "USERNAME"                , required => 1, size => 48  },
    { name => "PASSWORD"                , required => 1, size => 64  },
    { name => "NAME"                    , required => 1, size => 128 },
    { name => "EMAIL"                   , required => 1, size => 128 },
    { name => "OTHER_EMAILS"            , required => 0              },
    { name => "URL"                     , required => 0, size => 256 },
    { name => "STATUS"                  , required => 1              },
    { name => "LEVEL"                   , required => 1              }
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

  if ($RECORD{'USERNAME'} && $in{'DB'}->BinarySelect(TABLE => "UserAccounts", KEY => $RECORD{'USERNAME'})) {
    push(@Error, "ALREADYEXISTS-USERNAME");
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Inserting data...                                                    #

  $RECORD{'CREATE_SECOND'} = time;
  $RECORD{'CREATE_DATE'}   = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}   = &Standard::ConvertEpochToTime($RECORD{'CREATE_SECOND'});

  (
    $in{'DB'}->Insert(
      TABLE   => "UserAccounts",
      VALUES  => \%RECORD
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateUser->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;