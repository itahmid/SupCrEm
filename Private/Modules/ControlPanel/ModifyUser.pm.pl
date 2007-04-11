###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/ModifyUser.pm.pl -> ModifyUser module                          #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::ModifyUser;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/ModifyUser.pm.pl";

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
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_MODIFY_USERS'});

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
    SORT    => "USERNAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyUser->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_MODIFY_USERS'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'USERNAME'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my $UserAccount = $in{'DB'}->BinarySelect(
    TABLE => "UserAccounts",
    KEY   => $SD::QUERY{'USERNAME'}
  );
  unless ($UserAccount) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my %INPUT;
  
  $INPUT{'USER_ACCOUNT'} = $UserAccount;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyUser->new();

  &Standard::PrintHTMLHeader();
  print $Skin->view(input => \%INPUT, error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => $GENERAL->{'ALLOW_SUPPORT_MODIFY_USERS'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'USERNAME'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my $UserAccount = $in{'DB'}->BinarySelect(
    TABLE => "UserAccounts",
    KEY   => $SD::QUERY{'USERNAME'}
  );
  unless ($UserAccount) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my @Fields = (
    { name => "PASSWORD"                , required => 1, size => 64  },
    { name => "NAME"                    , required => 1, size => 128 },
    { name => "EMAIL"                   , required => 1, size => 128 },
    { name => "OTHER_EMAILS"            , required => 0              },
    { name => "URL"                     , required => 0, size => 256 },
    { name => "STATUS"                  , required => 1              },
    { name => "LEVEL"                   , required => 1              }
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
  
  if (scalar(@Error) >= 1) {
    $self->view(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  (
    $in{'DB'}->Update(
      TABLE   => "UserAccounts",
      VALUES  => \%RECORD,
      KEY     => $SD::QUERY{'USERNAME'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $RECORD{'USERNAME'} = $SD::QUERY{'USERNAME'};

  $INPUT{'RECORD'} = \%RECORD;
  $INPUT{'USER_ACCOUNT'} = $UserAccount;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyUser->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;