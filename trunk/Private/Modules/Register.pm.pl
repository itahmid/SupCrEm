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
# Register.pm.pl -> Register module                                           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Register;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";

use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/Register.pm.pl";

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
  # Printing page...                                                     #

  my $Skin = Skin::Register->new();

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
  # Checking fields...                                                   #

  my @Fields = (
    { name => "USERNAME"                , required => 1, size => 48  },
    { name => "PASSWORD"                , required => 1, size => 64  },
    { name => "NAME"                    , required => 1, size => 128 },
    { name => "EMAIL"                   , required => 1, size => 128 },
    { name => "OTHER_EMAILS"            , required => 0              },
    { name => "URL"                     , required => 0, size => 256 }
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

  if ($SD::QUERY{'FORM_PASSWORD2'} eq "") {
    push(@Error, "MISSING-PASSWORD2");
  }
  
  if ($RECORD{'PASSWORD'} ne $SD::QUERY{'FORM_PASSWORD2'}) {
    push(@Error, "INVALID-PASSWORD");
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

  $RECORD{'STATUS'}        = "50";
  $RECORD{'LEVEL'}         = "30";
  $RECORD{'CREATE_SECOND'} = time;
  $RECORD{'CREATE_DATE'}   = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}   = &Standard::ConvertEpochToTime($RECORD{'CREATE_SECOND'});

  (
    $in{'DB'}->Insert(
      TABLE   => "UserAccounts",
      VALUES  => \%RECORD
    )
  ) || &Error::Error("SD", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::Register->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;