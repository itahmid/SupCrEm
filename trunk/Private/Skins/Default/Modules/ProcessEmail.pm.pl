###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ProcessEmail.pm.pl -> ProcessEmail skin module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::ProcessEmail;

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
# error subroutine
sub error {
  my $self = shift;
  my %in = (error => "", input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my %FIELDS;
  
  $FIELDS{'message'} = $in{'input'}->{'MESSAGE'};
  $FIELDS{'account'} = $in{'input'}->{'ACCOUNT'};
  $FIELDS{'ticket'}  = $in{'input'}->{'TICKET'};
  $FIELDS{'category'} = $in{'input'}->{'CATEGORY'};

  #----------------------------------------------------------------------#
  # Printing email...                                                    #

  my $LANGUAGE = &Standard::GetLanguage("ProcessEmail");
  
  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});
  $FIELDS{'error'} = &Standard::Substitute(
    INPUT     => \$in{'error'},
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
  
  my %Return;

  $Return{'MESSAGE'} = &Standard::Substitute(
    INPUT     => "Emails/ProcessEmail-Error.txt",
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
  $Return{'TO'} = $in{'input'}->{'MESSAGE'}->{'FROM_EMAIL'};
  
  if ($in{'input'}->{'CATEGORY'}) {
    $Return{'FROM'} = "\"".$in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'}."\" <".$in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'}.">";
  } else {
    $Return{'FROM'} = "\"".$GENERAL->{'DESK_TITLE'}."\" <".$in{'input'}->{'MESSAGE'}->{'TO'}.">";
  }
  
  if ($in{'input'}->{'MESSAGE'}->{'SUBJECT'}) {
    if ($in{'input'}->{'MESSAGE'}->{'SUBJECT'} =~ /^Re/i) {
      $Return{'SUBJECT'} = $in{'input'}->{'MESSAGE'}->{'SUBJECT'};
    } else {
      $Return{'SUBJECT'} = "Re: ".$in{'input'}->{'MESSAGE'}->{'SUBJECT'};
    }
  } else {
    $Return{'SUBJECT'} = "Re: (Your Submission)";
  }
  
  $Return{'HEADERS'}->{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_USER_EMAILS'});

  return %Return;
}

###############################################################################
# ticket subroutine
sub ticket {
  my $self = shift;
  my %in = (type => "", input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my %FIELDS;
  
  $FIELDS{'message'}  = $in{'input'}->{'MESSAGE'};
  $FIELDS{'account'}  = $in{'input'}->{'ACCOUNT'};
  $FIELDS{'category'} = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}   = $in{'input'}->{'RECORD'};

  $FIELDS{'staffaccount'} = $in{'input'}->{'STAFF_ACCOUNT'};

  #----------------------------------------------------------------------#
  # Printing email...                                                    #

  my $LANGUAGE = &Standard::GetLanguage("ProcessEmail");

  my %Return;

  if ($in{'type'} eq "staff") {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ProcessEmail-Ticket-Staff.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'};
    $Return{'SUBJECT'} = &Standard::Substitute(
      INPUT     => \$LANGUAGE->{'STAFFEMAILSUBJECT-TICKET'},
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_ADMIN_EMAILS'});
  } else {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ProcessEmail-Ticket-User.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'MESSAGE'}->{'FROM_EMAIL'};
    $Return{'FROM'} = "\"".$in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'}."\" <".$in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'}.">";
    $Return{'SUBJECT'} = "[SD-".$in{'input'}->{'RECORD'}->{'TID'}."] ".$in{'input'}->{'RECORD'}->{'SUBJECT'};
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_USER_EMAILS'});
  }

  return %Return;
}

###############################################################################
# note subroutine
sub note {
  my $self = shift;
  my %in = (type => "", input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my %FIELDS;
  
  $FIELDS{'message'}  = $in{'input'}->{'MESSAGE'};
  $FIELDS{'account'}  = $in{'input'}->{'ACCOUNT'};
  $FIELDS{'ticket'}  = $in{'input'}->{'TICKET'};
  $FIELDS{'category'} = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}   = $in{'input'}->{'RECORD'};

  $FIELDS{'staffaccount'} = $in{'input'}->{'STAFF_ACCOUNT'};

  #----------------------------------------------------------------------#
  # Printing email...                                                    #

  my $LANGUAGE = &Standard::GetLanguage("ProcessEmail");

  my %Return;

  if ($in{'type'} eq "ownedstaff") {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ProcessEmail-Note-OwnedStaff.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'};
    $Return{'SUBJECT'} = &Standard::Substitute(
      INPUT     => \$LANGUAGE->{'STAFFEMAILSUBJECT-OWNEDNOTE'},
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_ADMIN_EMAILS'});
  } elsif ($in{'type'} eq "unownedstaff") {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ProcessEmail-Note-UnownedStaff.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'};
    $Return{'SUBJECT'} = &Standard::Substitute(
      INPUT     => \$LANGUAGE->{'STAFFEMAILSUBJECT-UNOWNEDNOTE'},
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_ADMIN_EMAILS'});
  } else {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ProcessEmail-Note-User.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'MESSAGE'}->{'FROM_EMAIL'};
    $Return{'FROM'} = "\"".$in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'}."\" <".$in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'}.">";
    $Return{'SUBJECT'} = "Re: [SD-".$in{'input'}->{'RECORD'}->{'TID'}."] ".$in{'input'}->{'RECORD'}->{'SUBJECT'};
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_USER_EMAILS'});
  }

  return %Return;
}

1;