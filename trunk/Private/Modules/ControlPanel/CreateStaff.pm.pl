###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/CreateStaff.pm.pl -> CreateStaff module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::CreateStaff;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/CreateStaff.pm.pl";

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
  # Getting data...                                                      #

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );
  
  my %INPUT;
  
  $INPUT{'CATEGORIES'} = $Categories;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateStaff->new();

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
    { name => "USERNAME"                , required => 1, size => 48  },
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

  if ($RECORD{'USERNAME'} && $in{'DB'}->BinarySelect(TABLE => "StaffAccounts", KEY => $RECORD{'USERNAME'})) {
    push(@Error, "ALREADYEXISTS-USERNAME");
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Inserting data...                                                    #

  if ($SD::QUERY{'FORM_CATEGORIES_ALL'}) {
    $RECORD{'CATEGORIES'} = "*";
  } elsif ($SD::QUERY{'FORM_CATEGORIES'}) {
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
    $in{'DB'}->Insert(
      TABLE   => "StaffAccounts",
      VALUES  => \%RECORD
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateStaff->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;