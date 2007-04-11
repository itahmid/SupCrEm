###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/CreateCategory.pm.pl -> CreateCategory module                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::CreateCategory;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/CreateCategory.pm.pl";

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

  my $Skin = Skin::CP::CreateCategory->new();

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
    { name => "NAME"         , required => 1, size => 128 },
    { name => "DESCRIPTION"  , required => 0, size => 512 },
    { name => "CONTACT_NAME" , required => 1, size => 128 },
    { name => "CONTACT_EMAIL", required => 1, size => 128 }
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

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Inserting data...                                                    #

  (
    $RECORD{'ID'} = $in{'DB'}->Insert(
      TABLE   => "Categories",
      VALUES  => \%RECORD
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateCategory->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;