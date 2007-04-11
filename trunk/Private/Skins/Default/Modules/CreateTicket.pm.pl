###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/CreateTicket.pm.pl -> CreateTicket skin module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CreateTicket;

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

  $FIELDS{'error'}      = &Standard::ProcessError(LANGUAGE => "CreateTicket", ERROR => $in{'error'});
  $FIELDS{'categories'} = $in{'input'}->{'CATEGORIES'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "CreateTicket.htm",
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

  $FIELDS{'category'}    = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}      = $in{'input'}->{'RECORD'};
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "DoCreateTicket.htm",
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
}

###############################################################################
# email subroutine
sub email {
  my $self = shift;
  my %in = (type => "", input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my %FIELDS;
  
  $FIELDS{'account'}  = $SD::USER{'ACCOUNT'};
  $FIELDS{'category'} = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}   = $in{'input'}->{'RECORD'};

  $FIELDS{'staffaccount'} = $in{'input'}->{'STAFF_ACCOUNT'};

  #----------------------------------------------------------------------#
  # Printing email...                                                    #

  my $LANGUAGE = &Standard::GetLanguage("CreateTicket");

  my %Return;

  if ($in{'type'} eq "staff") {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/CreateTicket-Staff.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'};
    $Return{'SUBJECT'} = &Standard::Substitute(
      INPUT     => \$LANGUAGE->{'EMAILSUBJECT-STAFF'},
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_ADMIN_EMAILS'});
  } else {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/CreateTicket-User.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'RECORD'}->{'EMAIL'};
    $Return{'FROM'} = "\"".$in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'}."\" <".$in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'}.">";
    $Return{'SUBJECT'} = "[SD-".$in{'input'}->{'RECORD'}->{'TID'}."] ".$in{'input'}->{'RECORD'}->{'SUBJECT'};
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_USER_EMAILS'});
  }

  return %Return;
}

1;