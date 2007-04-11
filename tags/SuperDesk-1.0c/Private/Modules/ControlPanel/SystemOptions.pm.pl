###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/SystemOptions.pm.pl -> SystemOptions module                    #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::SystemOptions;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Variables.pm.pl";

use strict;

require "ControlPanel/Output/SystemOptions.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::SystemOptions->new();

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
  
  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
    { name => "DB_PATH"         , required => 1 },
    { name => "TEMP_PATH"       , required => 1 },
    { name => "LOGS_PATH"       , required => 1 },
    { name => "BACKUP_PATH"     , required => 1 },
    { name => "CACHE_PATH"      , required => 1 },
    { name => "PUBLIC_PATH"     , required => 1 },
    { name => "SCRIPT_URL"      , required => 1 },
    { name => "PUBLIC_URL"      , required => 1 },
    { name => "DB_PREFIX"       , required => 0 },
    { name => "DB_HOST"         , required => 0 },
    { name => "DB_PORT"         , required => 0 },
    { name => "DB_NAME"         , required => 0 },
    { name => "DB_USERNAME"     , required => 0 },
    { name => "DB_PASSWORD"     , required => 0 },
    { name => "FLOCK"           , required => 1 },
    { name => "MAIL_TYPE"       , required => 1 },
    { name => "SENDMAIL"        , required => 0 },
    { name => "SMTP_SERVER"     , required => 0 },
    { name => "LOG_ERRORS"      , required => 1 },
    { name => "START_TAG"       , required => 1 },
    { name => "END_TAG"         , required => 1 },
    { name => "LOCALTIME_OFFSET", required => 0 },
    { name => "SHOW_CGI_ERRORS" , required => 1 },
    { name => "CACHING"         , required => 1 }
  );

  my (%RECORD, @Error);

  foreach my $field (@Fields) {
    if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}} eq "") {
      push(@Error, "MISSING-".$field->{'name'});
    } else {
      $RECORD{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
    }
  }

  if ($SYSTEM->{'DB_TYPE'} eq "mysql") {
    push(@Error, "MISSING-DB_HOST") if (!$RECORD{'DB_HOST'});
    push(@Error, "MISSING-DB_PORT") if (!$RECORD{'DB_PORT'});
    push(@Error, "MISSING-DB_NAME") if (!$RECORD{'DB_NAME'});
    push(@Error, "MISSING-DB_USERNAME") if (!$RECORD{'DB_USERNAME'});
    push(@Error, "MISSING-DB_PASSWORD") if (!$RECORD{'DB_PASSWORD'});
  } elsif ($SYSTEM->{'DB_TYPE'} eq "mssql") {
    push(@Error, "MISSING-DB_NAME") if (!$RECORD{'DB_NAME'});
    push(@Error, "MISSING-DB_USERNAME") if (!$RECORD{'DB_USERNAME'});
    push(@Error, "MISSING-DB_PASSWORD") if (!$RECORD{'DB_PASSWORD'});
  }
  
  if ($RECORD{'MAIL_TYPE'} eq "SENDMAIL") {
    push(@Error, "MISSING-SENDMAIL") if (!$RECORD{'SENDMAIL'});
  } elsif ($RECORD{'MAIL_TYPE'} eq "SMTP") {
    push(@Error, "MISSING-SMTP_SERVER") if (!$RECORD{'SMTP_SERVER'});
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  my $Variables = Variables->new();
  
  $Variables->Update(
    FILE      => "$SD::PATH/Private/Variables/System.pm.pl",
    PACKAGE   => "System",
    VARIABLE  => "SYSTEM",
    VALUES    => \%RECORD
  ) || &Error::Error("CP", MESSAGE => "Error updating variable file. $Variables->{'ERROR'}", "$SD::PATH/Private/Variables/System.pm.pl");
  
  my %INPUT;
  
  $INPUT{'RECORD'} = \%RECORD;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::SystemOptions->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;