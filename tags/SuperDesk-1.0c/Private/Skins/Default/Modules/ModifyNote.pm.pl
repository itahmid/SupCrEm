###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ModifyNote.pm.pl -> ModifyNote skin module                            #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::ModifyNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use strict;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless ($self, $class);
}

sub DESTROY { }

###############################################################################
# show subroutine
sub show {
  my $self = shift;
  my %in = (input => undef, error => "", @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my %FIELDS;

  $FIELDS{'error'}      = &Standard::ProcessError(LANGUAGE => "ModifyNote", ERROR => $in{'error'});
  $FIELDS{'ticket'}     = $in{'input'}->{'TICKET'};
  $FIELDS{'note'}       = $in{'input'}->{'NOTE'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "ModifyNote.htm",
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  $in{'input'}->{'RECORD'}->{'MESSAGE'} = &Standard::HTMLize($in{'input'}->{'RECORD'}->{'MESSAGE'});
  
  my %FIELDS;

  $FIELDS{'note'}        = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}      = $in{'input'}->{'RECORD'};
  $FIELDS{'ticket'}      = $in{'input'}->{'TICKET'};
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "DoModifyNote.htm",
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
}

1;