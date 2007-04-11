###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/Login.pm.pl -> Login skin module                                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::Login;

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
  
  $FIELDS{'error'} = &Standard::ProcessError(LANGUAGE => "Login", ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "Login.htm",
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
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "DoLogin.htm",
    STANDARD  => 1
  );
}

1;