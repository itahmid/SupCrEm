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
# ModifyAccount.pm.pl -> ModifyAccount module                                 #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package ModifyAccount;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "Skins/$SD::GLOBAL{'SKIN'}/Modules/ModifyAccount.pm.pl";

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
  # Printing page...                                                     #

  my $Skin = Skin::ModifyAccount->new();

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

  &Authenticate::SD(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
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

  if ($SD::QUERY{'FORM_OLD_PASSWORD'} && $SD::QUERY{'FORM_NEW_PASSWORD1'} && $SD::QUERY{'FORM_NEW_PASSWORD2'}) {
    if ($SD::QUERY{'FORM_NEW_PASSWORD1'} ne $SD::QUERY{'FORM_NEW_PASSWORD2'}) {
      push(@Error, "INVALID-PASSWORD");
    } else {
      $RECORD{'PASSWORD'} = $SD::QUERY{'FORM_NEW_PASSWORD1'};
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
      KEY     => $SD::USER{'ACCOUNT'}->{'USERNAME'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

  $RECORD{'USERNAME'} = $SD::USER{'ACCOUNT'}->{'USERNAME'};

  if ($RECORD{'PASSWORD'}) {
    (
      $in{'DB'}->Update(
        TABLE   => "Sessions",
        VALUES  => {
          PASSWORD  => $RECORD{'PASSWORD'}
        },
        KEY     => $SD::USER{'SESSION'}->{'ID'}
      )
    ) || &Error::Error("CP", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");
  }

  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::ModifyAccount->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;