###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ModifyTicket.pm.pl -> ModifyTicket skin module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::ModifyTicket;

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

  foreach my $note (@{ $in{'input'}->{'NOTES'} }) {
    $note->{'MESSAGE'} = &Standard::HTMLize($note->{'MESSAGE'});
    if ($note->{'AUTHOR_TYPE'} eq "USER") {
      $note->{'author'} = $SD::USER{'ACCOUNT'};
    } else {
      $note->{'author'} = $in{'input'}->{'STAFF_ACCOUNTS'}->[$in{'input'}->{'STAFF_ACCOUNTS_IX'}->{$note->{'AUTHOR'}}];
    }
  }

  my %FIELDS;

  $FIELDS{'error'}      = &Standard::ProcessError(LANGUAGE => "ModifyTicket", ERROR => $in{'error'});
  $FIELDS{'ticket'}     = $in{'input'}->{'TICKET'};
  $FIELDS{'notes'}      = $in{'input'}->{'NOTES'};
  $FIELDS{'category'}   = $in{'input'}->{'CATEGORY'};
  $FIELDS{'categories'} = $in{'input'}->{'CATEGORIES'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "ModifyTicket.htm",
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

  $in{'input'}->{'NOTE_RECORD'}->{'MESSAGE'} = &Standard::HTMLize($in{'input'}->{'NOTE_RECORD'}->{'MESSAGE'});
  
  my %FIELDS;

  $FIELDS{'ticket'}      = $in{'input'}->{'TICKET'};
  $FIELDS{'category'}    = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}      = $in{'input'}->{'RECORD'};
  $FIELDS{'note_record'} = $in{'input'}->{'NOTE_RECORD'};
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  return &Standard::Substitute(
    INPUT     => "DoModifyTicket.htm",
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
  $FIELDS{'ticket'}  = $in{'input'}->{'RECORD'};
  $FIELDS{'category'} = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}   = $in{'input'}->{'NOTE_RECORD'};

  $FIELDS{'staffaccount'} = $in{'input'}->{'STAFF_ACCOUNT'};

  #----------------------------------------------------------------------#
  # Printing email...                                                    #

  my $LANGUAGE = &Standard::GetLanguage("ModifyTicket");

  my %Return;

  if ($in{'type'} eq "ownedstaff") {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ModifyTicket-OwnedStaff.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'};
    $Return{'SUBJECT'} = &Standard::Substitute(
      INPUT     => \$LANGUAGE->{'EMAILSUBJECT-OWNEDSTAFF'},
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_ADMIN_EMAILS'});
  } elsif ($in{'type'} eq "unownedstaff") {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ModifyTicket-UnownedStaff.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'};
    $Return{'SUBJECT'} = &Standard::Substitute(
      INPUT     => \$LANGUAGE->{'EMAILSUBJECT-UNOWNEDSTAFF'},
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_ADMIN_EMAILS'});
  } else {
    $Return{'MESSAGE'} = &Standard::Substitute(
      INPUT     => "Emails/ModifyTicket-User.txt",
      STANDARD  => 1,
      FIELDS    => \%FIELDS
    );
    $Return{'TO'} = $in{'input'}->{'TICKET'}->{'EMAIL'};
    $Return{'FROM'} = "\"".$in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'}."\" <".$in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'}.">";
    $Return{'SUBJECT'} = "Re: [SD-".$in{'input'}->{'RECORD'}->{'TID'}."] ".$in{'input'}->{'RECORD'}->{'SUBJECT'};
    $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_USER_EMAILS'});
  }

  return %Return;
}

1;