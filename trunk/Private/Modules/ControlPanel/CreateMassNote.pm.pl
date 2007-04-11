###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/CreateMassNote.pm.pl -> CreateMassNote module                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::CreateMassNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Mail.pm.pl";

use File::Copy;
use POSIX;
use strict;

require "ControlPanel/Output/CreateMassNote.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my %Where;
  
  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    $Where{'ID'} = \@categories;
  }

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => \%Where,
    MATCH   => "ANY",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateMassNote->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

###############################################################################
# search subroutine
sub search {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'});
  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*" && scalar($SD::CGI->param('FORM_CATEGORIES')) >= 1) {
    my @formcategories = $SD::CGI->param('FORM_CATEGORIES');
    my @usercategories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $error;
    foreach my $formcategory (@formcategories) {
      my $found;
      foreach my $usercategory (@usercategories) {
        $found = 1 and last if ($usercategory == $formcategory);
      }
      $error = 1 and last unless ($found);
    }
    if ($error) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
  }

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    SORT    => $SD::QUERY{'FORM_SORT_FIELD'} || "ID",
    BY      => $SD::QUERY{'FORM_SORT_BY'} || "A-Z"
  );

  my @Categories      = $SD::CGI->param('FORM_CATEGORIES');
  my @Authors         = $SD::CGI->param('FORM_AUTHORS');
  my @DeliveryMethods = $SD::CGI->param('FORM_DELIVERY_METHODS');
  my @Priorities      = $SD::CGI->param('FORM_PRIORITIES');
  my @Severities      = $SD::CGI->param('FORM_SEVERITIES');
  my @Status          = $SD::CGI->param('FORM_STATUS');
  my @OwnedBy         = $SD::CGI->param('FORM_OWNED_BY');

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => {
      ID  => \@Categories
    },
    MATCH   => "ANY"
  );
  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
    WHERE   => {
      USERNAME  => \@Authors
    },
    MATCH   => "ANY"
  );
  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    WHERE   => {
      USERNAME  => \@OwnedBy
    },
    MATCH   => "ANY"
  );

  my %Categories      = $self->myArrayToHash($Categories, "ID");
  my %Authors         = $self->myArrayToHash($UserAccounts, "USERNAME");
  my %FormAuthors     = $self->myArrayToHash(\@Authors);
  my %OwnedBy         = $self->myArrayToHash($StaffAccounts, "USERNAME");
  my %DeliveryMethods = $self->myArrayToHash(\@DeliveryMethods);
  my %Priorities      = $self->myArrayToHash(\@Priorities);
  my %Severities      = $self->myArrayToHash(\@Severities);
  my %Status          = $self->myArrayToHash(\@Status);

  my @Tickets;
  foreach my $ticket (@{ $Tickets }) {
    if ($SD::QUERY{'FORM_BOOLEAN'} eq "AND") {
      next if ($SD::QUERY{'FORM_ID'} && $ticket->{'ID'} != $SD::QUERY{'FORM_ID'});
      
      if ($SD::QUERY{'FORM_SUBJECT_RE'} eq "is") {
        next if ($SD::QUERY{'FORM_SUBJECT'} && $ticket->{'SUBJECT'} ne $SD::QUERY{'FORM_SUBJECT'});
      } elsif ($SD::QUERY{'FORM_SUBJECT_RE'} eq "contains") {
        next if ($SD::QUERY{'FORM_SUBJECT'} && $ticket->{'SUBJECT'} !~ /$SD::QUERY{'FORM_SUBJECT'}/i);
      }
      
      next unless ($Categories{ $ticket->{'CATEGORY'} });
      
      my $ok;
      if (scalar(@Authors) < 1 || $FormAuthors{'[GUESTS]'}) {
        goto CONT if ($ticket->{'AUTHOR'});
        if ($SD::QUERY{'FORM_GUEST_NAME_RE'} eq "is") {
          goto CONT if ($SD::QUERY{'FORM_GUEST_NAME'} && $ticket->{'GUEST_NAME'} ne $SD::QUERY{'FORM_GUEST_NAME'});
        } elsif ($SD::QUERY{'FORM_GUEST_NAME_RE'} eq "contains") {
          goto CONT if ($SD::QUERY{'FORM_GUEST_NAME'} && $ticket->{'GUEST_NAME'} !~ /$SD::QUERY{'FORM_GUEST_NAME'}/i);
        }
        if ($SD::QUERY{'FORM_EMAIL_RE'} eq "is") {
          goto CONT if ($SD::QUERY{'FORM_EMAIL'} && $ticket->{'EMAIL'} ne $SD::QUERY{'FORM_EMAIL'});
        } elsif ($SD::QUERY{'FORM_EMAIL_RE'} eq "contains") {
          goto CONT if ($SD::QUERY{'FORM_EMAIL'} && $ticket->{'EMAIL'} !~ /$SD::QUERY{'FORM_EMAIL'}/i);
        }
        $ok = 1;
      }
CONT:
      next unless ($ok || $Authors{ $ticket->{'AUTHOR'} });
      next unless (scalar(@DeliveryMethods) < 1 || $DeliveryMethods{ $ticket->{'DELIVERY_METHOD'} });
      next unless (scalar(@Priorities) < 1 || $Priorities{ $ticket->{'PRIORITY'} });
      next unless (scalar(@Severities) < 1 || $Severities{ $ticket->{'SEVERITY'} });
      next unless (scalar(@Status) < 1 || $Status{ $ticket->{'STATUS'} });
      next if ($ticket->{'OWNED_BY'} && !$OwnedBy{ $ticket->{'OWNED_BY'} });
      
      if ($SD::QUERY{'FORM_CREATE_SECOND'} && $SD::QUERY{'FORM_CREATE_SECOND_OPER'} eq "more") {
        next unless ($ticket->{'CREATE_SECOND'} > ($SD::QUERY{'FORM_CREATE_SECOND'} * 24 * 60 * 60));
      } elsif ($SD::QUERY{'FORM_CREATE_SECOND'} && $SD::QUERY{'FORM_CREATE_SECOND_OPER'} eq "less") {
        next unless ($ticket->{'CREATE_SECOND'} < ($SD::QUERY{'FORM_CREATE_SECOND'} * 24 * 60 * 60));
      }

      if ($SD::QUERY{'FORM_UPDATE_SECOND'} && $SD::QUERY{'FORM_UPDATE_SECOND_OPER'} eq "more") {
        next unless ($ticket->{'UPDATE_SECOND'} > ($SD::QUERY{'FORM_UPDATE_SECOND'} * 24 * 60 * 60));
      } elsif ($SD::QUERY{'FORM_UPDATE_SECOND'} && $SD::QUERY{'FORM_UPDATE_SECOND_OPER'} eq "less") {
        next unless ($ticket->{'UPDATE_SECOND'} < ($SD::QUERY{'FORM_UPDATE_SECOND'} * 24 * 60 * 60));
      }

      push(@Tickets, $ticket);
    } else {
      goto END if ($SD::QUERY{'FORM_ID'} && $ticket->{'ID'} == $SD::QUERY{'FORM_ID'});
      
      if ($SD::QUERY{'FORM_SUBJECT_RE'} eq "is") {
        goto END if ($SD::QUERY{'FORM_SUBJECT'} && $ticket->{'SUBJECT'} eq $SD::QUERY{'FORM_SUBJECT'});
      } elsif ($SD::QUERY{'FORM_SUBJECT_RE'} eq "contains") {
        goto END if ($SD::QUERY{'FORM_SUBJECT'} && $ticket->{'SUBJECT'} =~ /$SD::QUERY{'FORM_SUBJECT'}/i);
      }
      
      goto END if ($Categories{ $ticket->{'CATEGORY'} });

      if ($FormAuthors{'[GUESTS]'} && !$ticket->{'AUTHOR'}) {
        if ($SD::QUERY{'FORM_GUEST_NAME_RE'} eq "is") {
          goto END if ($SD::QUERY{'FORM_GUEST_NAME'} && $ticket->{'GUEST_NAME'} eq $SD::QUERY{'FORM_GUEST_NAME'});
        } elsif ($SD::QUERY{'FORM_GUEST_NAME_RE'} eq "contains") {
          goto END if ($SD::QUERY{'FORM_GUEST_NAME'} && $ticket->{'GUEST_NAME'} =~ /$SD::QUERY{'FORM_GUEST_NAME'}/i);
        }
        if ($SD::QUERY{'FORM_EMAIL_RE'} eq "is") {
          goto END if ($SD::QUERY{'FORM_EMAIL'} && $ticket->{'EMAIL'} eq $SD::QUERY{'FORM_EMAIL'});
        } elsif ($SD::QUERY{'FORM_EMAIL_RE'} eq "contains") {
          goto END if ($SD::QUERY{'FORM_EMAIL'} && $ticket->{'EMAIL'} =~ /$SD::QUERY{'FORM_EMAIL'}/i);
        }
      }

      goto END if ($Authors{ $ticket->{'AUTHOR'} });
      goto END if ($DeliveryMethods{ $ticket->{'DELIVERY_METHOD'} });
      goto END if ($Priorities{ $ticket->{'PRIORITY'} });
      goto END if ($Severities{ $ticket->{'SEVERITY'} });
      goto END if ($Status{ $ticket->{'STATUS'} });
      goto END if ($OwnedBy{ $ticket->{'OWNED_BY'} });
      
      if ($SD::QUERY{'FORM_CREATE_SECOND'} && $SD::QUERY{'FORM_CREATE_SECOND_OPER'} eq "more") {
        goto END if ($ticket->{'CREATE_SECOND'} > ($SD::QUERY{'FORM_CREATE_SECOND'} * 24 * 60 * 60));
      } elsif ($SD::QUERY{'FORM_CREATE_SECOND'} && $SD::QUERY{'FORM_CREATE_SECOND_OPER'} eq "less") {
        goto END if ($ticket->{'CREATE_SECOND'} < ($SD::QUERY{'FORM_CREATE_SECOND'} * 24 * 60 * 60));
      }

      if ($SD::QUERY{'FORM_UPDATE_SECOND'} && $SD::QUERY{'FORM_UPDATE_SECOND_OPER'} eq "more") {
        goto END if ($ticket->{'UPDATE_SECOND'} > ($SD::QUERY{'FORM_UPDATE_SECOND'} * 24 * 60 * 60));
      } elsif ($SD::QUERY{'FORM_UPDATE_SECOND'} && $SD::QUERY{'FORM_UPDATE_SECOND_OPER'} eq "less") {
        goto END if ($ticket->{'UPDATE_SECOND'} < ($SD::QUERY{'FORM_UPDATE_SECOND'} * 24 * 60 * 60));
      }

END:
      push(@Tickets, $ticket);
    }
  }

  my $Page = $SD::QUERY{'Page'} || 1;
  my $TotalTickets = scalar(@Tickets);
  my $Start = ($Page - 1) * ($SD::QUERY{'FORM_TICKETS_PER_PAGE'} || 10);
  my $Finish = $Start + ($SD::QUERY{'FORM_TICKETS_PER_PAGE'} || 10) - 1;
     $Finish = $#Tickets if ($Finish > $#Tickets);

  @Tickets = @Tickets[$Start..$Finish];

  my %INPUT;

  $INPUT{'TOTAL_TICKETS'} = $TotalTickets;
  $INPUT{'TOTAL_PAGES'} = ceil($INPUT{'TOTAL_TICKETS'} / ($SD::QUERY{'FORM_TICKETS_PER_PAGE'} || 10));
  $INPUT{'TOTAL_PAGES'} = 1 if ($INPUT{'TOTAL_PAGES'} < 1);
  $INPUT{'PAGE'} = $Page;

  $INPUT{'TICKETS'} = \@Tickets;
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;
  $INPUT{'USER_ACCOUNTS'} = $UserAccounts;
  $INPUT{'USER_ACCOUNTS_IX'} = $UserAccountsIndex;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;
  $INPUT{'STAFF_ACCOUNTS_IX'} = $StaffAccountsIndex;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateMassNote->new();

  &Standard::PrintHTMLHeader();
  print $Skin->search(input => \%INPUT);
  
  return 1;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #

  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @TID = $SD::CGI->param('TID');

  if (scalar(@TID) < 1) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      ID  => \@TID
    },
    MATCH   => "ANY",
    SORT    => "ID",
    BY      => "A-Z"
  );

  my @Categories;
  foreach my $ticket (@{ $Tickets }) {
    if ($SD::ADMIN{'LEVEL'} != 100 && $ticket->{'OWNED_BY'} && $ticket->{'OWNED_BY'} ne $SD::ADMIN{'USERNAME'}) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
    push(@Categories, $ticket->{'CATEGORY'});
  }
  
  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => {
      ID  => \@Categories
    },
    MATCH   => "ANY"
  );

  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;

  $INPUT{'TICKETS'}         = $Tickets;
  $INPUT{'CATEGORIES'}      = $Categories;
  $INPUT{'CATEGORIES_IX'}   = $CategoriesIndex;
  $INPUT{'STAFF_ACCOUNTS'}  = $StaffAccounts;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateMassNote->new();

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

  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @TID = $SD::CGI->param('TID');

  if (scalar(@TID) < 1) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(
    TABLE   => "Tickets",
    WHERE   => {
      ID  => \@TID
    },
    MATCH   => "ANY",
    SORT    => "ID",
    BY      => "A-Z"
  );

  my (@Categories, @Authors);
  foreach my $ticket (@{ $Tickets }) {
    if ($SD::ADMIN{'LEVEL'} != 100 && $ticket->{'OWNED_BY'} && $ticket->{'OWNED_BY'} ne $SD::ADMIN{'USERNAME'}) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
    push(@Categories, $ticket->{'CATEGORY'});
    push(@Authors, $ticket->{'AUTHOR'}) if ($ticket->{'AUTHOR'});
  }
  
  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => {
      ID  => \@Categories
    },
    MATCH   => "ANY"
  );

  my ($UserAccounts, $UserAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "UserAccounts",
    WHERE   => {
      USERNAME  => \@Authors
    },
    MATCH   => "ANY"
  );

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "MESSAGE"      , required => 1              },
    { name => "AUTHOR"       , required => 1              },
    { name => "PRIVATE"      , required => 0              }
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

  if ($SD::ADMIN{'LEVEL'} != 100 && $RECORD{'AUTHOR'} ne $SD::ADMIN{'USERNAME'}) {
    push(@Error, "INVALID-AUTHOR");
  } else {
    my $author = $in{'DB'}->BinarySelect(
      TABLE   => "StaffAccounts",
      KEY     => $RECORD{'AUTHOR'}
    );
    if ($author) {
      $INPUT{'STAFF_ACCOUNT'} = $author;
    } else {
      push(@Error, "INVALID-AUTHOR");
    }
  }

  if (scalar(@Error) >= 1) {
    $self->view(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  $RECORD{'AUTHOR_TYPE'}      = "STAFF";
  $RECORD{'DELIVERY_METHOD'}  = "CP-STAFF";
  $RECORD{'CREATE_SECOND'}    = time;
  $RECORD{'CREATE_DATE'}      = &Standard::ConvertEpochToDate($RECORD{'CREATE_SECOND'});
  $RECORD{'CREATE_TIME'}      = &Standard::ConvertEpochToTime($RECORD{'CREATE_SECOND'});
  $RECORD{'UPDATE_SECOND'}    = $RECORD{'CREATE_SECOND'};
  $RECORD{'UPDATE_DATE'}      = $RECORD{'CREATE_DATE'};
  $RECORD{'UPDATE_TIME'}      = $RECORD{'CREATE_TIME'};

  if ($SD::QUERY{'FORM_SIGNATURE'} && $SD::ADMIN{'SIGNATURE'}) {
    $RECORD{'MESSAGE'} .= "\n" unless ($RECORD{'MESSAGE'} =~ /\n$/);
    $RECORD{'MESSAGE'} .= $SD::ADMIN{'SIGNATURE'};
  }

  my $Skin = Skin::CP::CreateMassNote->new();

  foreach my $ticket (@{ $Tickets }) {
    delete($RECORD{'ID'});
    $RECORD{'TID'} = $ticket->{'ID'};

    (
      $RECORD{'NID'} = $in{'DB'}->Insert(
        TABLE   => "Notes",
        VALUES  => \%RECORD
      )
    ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

    (
      $in{'DB'}->Update(
        TABLE   => "Tickets",
        VALUES  => {
          NOTES   => "\${NOTES}++"
        },
        KEY     => $ticket->{'ID'}
      )
    ) || &Error::Error("CP", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

    $INPUT{'RECORD'}        = \%RECORD;
    $INPUT{'TICKET'}        = $ticket;
    $INPUT{'CATEGORY'}      = $Categories->[$CategoriesIndex->{$ticket->{'CATEGORY'}}];
    $INPUT{'USER_ACCOUNT'}  = ($ticket->{'AUTHOR'} ? $UserAccounts->[$UserAccountsIndex->{$ticket->{'AUTHOR'}}] : {});

    $SD::QUERY{'FORM_NOTIFY_AUTHOR'} = 0 if ($RECORD{'PRIVATE'});
    if ($SD::QUERY{'FORM_NOTIFY_AUTHOR'}) {
      my %message = $Skin->email(input => \%INPUT);
      my $Mail = Mail->new();
         $Mail->Send(%message) || &Error::Error("CP", MESSAGE => "Error sending email to user. $Mail->{'ERROR'}");
    }
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

###############################################################################
# myArrayToHash subroutine
sub myArrayToHash {
  my $self = shift;
  my ($Array, $Var) = @_;

  my %Return;
  
  foreach my $key (@{ $Array }) {
    if ($Var) {
      $Return{ $key->{$Var} } = 1;
    } else {
      $Return{ $key } = 1;
    }
  }
  
  return %Return;
}

1;