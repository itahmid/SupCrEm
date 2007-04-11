###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/ModifyStaff.pm.pl -> ModifyStaff module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::ModifyStaff;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/ModifyStaff.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "USERNAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyStaff->new();

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

  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'USERNAME'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my $StaffAccount = $in{'DB'}->BinarySelect(
    TABLE => "StaffAccounts",
    KEY   => $SD::QUERY{'USERNAME'}
  );
  unless ($StaffAccount) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );
  
  my %INPUT;
  
  $INPUT{'STAFF_ACCOUNT'} = $StaffAccount;
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyStaff->new();

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

  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'USERNAME'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my $StaffAccount = $in{'DB'}->BinarySelect(
    TABLE => "StaffAccounts",
    KEY   => $SD::QUERY{'USERNAME'}
  );
  unless ($StaffAccount) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my @Fields = (
    { name => "PASSWORD"                , required => 1, size => 64  },
    { name => "NAME"                    , required => 1, size => 128 },
    { name => "EMAIL"                   , required => 1, size => 128 },
    { name => "STATUS"                  , required => 1              },
    { name => "LEVEL"                   , required => 1              },
    { name => "SIGNATURE"               , required => 0, size => 512 },
    { name => "NOTIFY_NEW_TICKETS"      , required => 0              },
    { name => "NOTIFY_NEW_NOTES_UNOWNED", required => 0              },
    { name => "NOTIFY_NEW_NOTES_OWNED"  , required => 0              }
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

  if ($SD::QUERY{'FORM_CATEGORIES_ALL'}) {
    $RECORD{'CATEGORIES'} = "*";
  } else {
    my @categories = $SD::CGI->param('FORM_CATEGORIES');
    $RECORD{'CATEGORIES'} = join(",", @categories);
    
    my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
      TABLE   => "Categories",
      WHERE   => {
        ID  => \@categories
      },
      MATCH   => "ANY"
    );
    
    $INPUT{'CATEGORIES'} = $Categories;
    $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;
  }

  (
    $in{'DB'}->Update(
      TABLE   => "StaffAccounts",
      VALUES  => \%RECORD,
      KEY     => $SD::QUERY{'USERNAME'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $RECORD{'USERNAME'} = $SD::QUERY{'USERNAME'};

  $INPUT{'RECORD'} = \%RECORD;
  $INPUT{'STAFF_ACCOUNT'} = $StaffAccount;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyStaff->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;