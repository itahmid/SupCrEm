###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/ModifyTicket.pm.pl -> ModifyTicket module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::ModifyTicket;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Mail.pm.pl";

use File::Copy;
use POSIX;
use strict;

require "ControlPanel/Output/ModifyTicket.pm.pl";

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

  my $Skin = Skin::CP::ModifyTicket->new();

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

  my $Skin = Skin::CP::ModifyTicket->new();

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

  if (!$SD::QUERY{'TID'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE => "Tickets",
    KEY   => $SD::QUERY{'TID'}
  );
  unless ($Ticket) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my $Category = $in{'DB'}->BinarySelect(
    TABLE => "Categories",
    KEY   => $Ticket->{'CATEGORY'}
  );
  
  my %Where;
  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $found;
    foreach my $category (@categories) {
      $found = 1 and last if ($Ticket->{'CATEGORY'} == $category);
    }
    unless ($found) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
    $Where{'ID'} = \@categories;
  }

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => \%Where,
    MATCH   => "ANY",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  if ($SD::ADMIN{'LEVEL'} != 100 && $Ticket->{'OWNED_BY'} && $Ticket->{'OWNED_BY'} ne $SD::ADMIN{'USERNAME'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }    

  my %INPUT;

  if ($Ticket->{'AUTHOR'}) {
    my $UserAccount = $in{'DB'}->BinarySelect(
      TABLE => "UserAccounts",
      KEY   => $Ticket->{'AUTHOR'}
    );
    $INPUT{'USER_ACCOUNT'} = $UserAccount;
  }
  
  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      TID => [$SD::QUERY{'TID'}]
    },
    MATCH   => "ALL",
    SORT    => "ID",
    BY      => "A-Z"
  );
  
  my ($StaffAccounts, $StaffAccountsIndex) = $in{'DB'}->Query(
    TABLE   => "StaffAccounts",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  $INPUT{'TICKET'} = $Ticket;
  $INPUT{'CATEGORY'} = $Category;
  $INPUT{'NOTES'} = $Notes;
  $INPUT{'STAFF_ACCOUNTS'} = $StaffAccounts;
  $INPUT{'STAFF_ACCOUNTS_IX'} = $StaffAccountsIndex;
  $INPUT{'CATEGORIES'} = $Categories;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ModifyTicket->new();

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

  if (!$SD::QUERY{'TID'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  my $Ticket = $in{'DB'}->BinarySelect(
    TABLE => "Tickets",
    KEY   => $SD::QUERY{'TID'}
  );
  unless ($Ticket) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my $found;
    foreach my $category (@categories) {
      $found = 1 and last if ($category == $Ticket->{'CATEGORY'});
    }
    unless ($found) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
  }

  my @Fields = (
    { name => "SUBJECT"      , required => 1, size => 512 },
    { name => "CATEGORY"     , required => 1              },
    { name => "PRIORITY"     , required => 1              },
    { name => "SEVERITY"     , required => 1              },
    { name => "STATUS"       , required => 1              },
    { name => "OWNED_BY"     , required => 0              }
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
  
  if ($RECORD{'CATEGORY'}) {
    my $category = $in{'DB'}->BinarySelect(
      TABLE   => "Categories",
      KEY     => $RECORD{'CATEGORY'}
    );
    if ($category) {
      $INPUT{'CATEGORY'} = $category;
    } else {
      push(@Error, "INVALID-CATEGORY");
    }
  }

  if ($RECORD{'OWNED_BY'}) {
    if ($SD::ADMIN{'LEVEL'} != 100 && $RECORD{'OWNED_BY'} ne $SD::ADMIN{'USERNAME'}) {
      push(@Error, "INVALID-OWNED_BY");
    } else {
      my $staff = $in{'DB'}->BinarySelect(
        TABLE   => "StaffAccounts",
        KEY     => $RECORD{'OWNED_BY'}
      );
      if ($staff) {
        if ($RECORD{'CATEGORY'} && $staff->{'CATEGORIES'} ne "*" && $staff->{'LEVEL'} != 100) {
          my @categories = split(/,/, $staff->{'CATEGORIES'});
          my $found;
          foreach my $category (@categories) {
            $found = 1 and last if ($category == $RECORD{'CATEGORY'});
          }
          unless ($found) {
            push(@Error, "INVALID-OWNED_BY");
          }
        }
        $INPUT{'STAFF_ACCOUNT'} = $staff;
      } else {
        push(@Error, "INVALID-OWNED_BY");
      }
    }
  }

  if ($SD::QUERY{'FORM_NOTE'}) {
    push(@Error, "MISSING-NOTE_SUBJECT") if ($SD::QUERY{'FORM_NOTE_SUBJECT'} eq "");
    push(@Error, "TOOLONG-NOTE_SUBJECT") if (length($SD::QUERY{'FORM_NOTE_SUBJECT'}) > 512);
    push(@Error, "MISSING-NOTE_MESSAGE") if ($SD::QUERY{'FORM_NOTE_MESSAGE'} eq "");
    push(@Error, "MISSING-NOTE_AUTHOR") if ($SD::QUERY{'FORM_NOTE_AUTHOR'} eq "");
    
    if ($SD::QUERY{'FORM_NOTE_AUTHOR'} ne "[TICKET-AUTHOR]") {
      if ($SD::ADMIN{'LEVEL'} != 100 && $SD::QUERY{'FORM_NOTE_AUTHOR'} ne $SD::ADMIN{'USERNAME'}) {
        push(@Error, "INVALID-NOTE_AUTHOR");
      } else {
        my $author = $in{'DB'}->BinarySelect(
          TABLE   => "StaffAccounts",
          KEY     => $SD::QUERY{'FORM_NOTE_AUTHOR'}
        );
        if ($author) {
          $INPUT{'NOTE_STAFF_ACCOUNT'} = $author;
        } else {
          push(@Error, "INVALID-NOTE_AUTHOR");
        }
      }
    }
  }

  if (scalar(@Error) >= 1) {
    $self->view(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  $RECORD{'UPDATE_SECOND'} = time;
  $RECORD{'UPDATE_DATE'}   = &Standard::ConvertEpochToDate($RECORD{'UPDATE_SECOND'});
  $RECORD{'UPDATE_TIME'}   = &Standard::ConvertEpochToTime($RECORD{'UPDATE_TIME'});

  $RECORD{'NOTES'}         = $Ticket->{'NOTES'} + 1 if ($SD::QUERY{'FORM_NOTE'});

  (
    $in{'DB'}->Update(
      TABLE   => "Tickets",
      VALUES  => \%RECORD,
      KEY     => $SD::QUERY{'TID'}
    )
  ) || &Error::Error("CP", MESSAGE => "Error updating record. $in{'DB'}->{'ERROR'}");

  $RECORD{'TID'} = $SD::QUERY{'TID'};

  $INPUT{'RECORD'} = \%RECORD;
  $INPUT{'TICKET'} = $Ticket;

  if ($Ticket->{'AUTHOR'}) {
    my $useraccount = $in{'DB'}->BinarySelect(
      TABLE   => "UserAccounts",
      KEY     => $Ticket->{'AUTHOR'}
    );
    $INPUT{'USER_ACCOUNT'} = $useraccount;
  }

  my $Skin = Skin::CP::ModifyTicket->new();

  if ($SD::QUERY{'FORM_NOTE'}) {
    my %NOTE;
    $NOTE{'TID'}     = $SD::QUERY{'TID'};
    $NOTE{'SUBJECT'} = $SD::QUERY{'FORM_NOTE_SUBJECT'};
    $NOTE{'MESSAGE'} = $SD::QUERY{'FORM_NOTE_MESSAGE'};
    
    if ($SD::QUERY{'FORM_NOTE_AUTHOR'} eq "[TICKET-AUTHOR]") {
      $NOTE{'AUTHOR'} = $Ticket->{'AUTHOR'};
      $NOTE{'AUTHOR_TYPE'} = "USER";
    } else {
      $NOTE{'AUTHOR'} = $SD::QUERY{'FORM_NOTE_AUTHOR'};
      $NOTE{'AUTHOR_TYPE'} = "STAFF";
    }
    
    $NOTE{'DELIVERY_METHOD'} = "CP-STAFF";
    $NOTE{'PRIVATE'}         = $SD::QUERY{'FORM_NOTE_PRIVATE'} || 0;
    $NOTE{'PRIVATE'}         = 0 if ($SD::QUERY{'FORM_NOTE_AUTHOR'} eq "[TICKET-AUTHOR]");
    $NOTE{'CREATE_SECOND'}   = time;
    $NOTE{'CREATE_DATE'}     = &Standard::ConvertEpochToDate($NOTE{'CREATE_SECOND'});
    $NOTE{'CREATE_TIME'}     = &Standard::ConvertEpochToTime($NOTE{'CREATE_SECOND'});
    $NOTE{'UPDATE_SECOND'}   = $NOTE{'CREATE_SECOND'};
    $NOTE{'UPDATE_DATE'}     = $NOTE{'CREATE_DATE'};
    $NOTE{'UPDATE_TIME'}     = $NOTE{'CREATE_TIME'};

    my $Filename = $SD::CGI->param('FORM_NOTE_ATTACHMENT');
    my $TempFile;
    if ($Filename) {
      $TempFile = $SD::CGI->tmpFileName($Filename);
      my @filename = split(/(\\|\/)/, $Filename);
      $Filename = $filename[$#filename];
      $NOTE{'ATTACHMENTS'} = $Filename;
    }

    $SD::QUERY{'FORM_NOTE_SIGNATURE'} = 0 if ($SD::QUERY{'FORM_NOTE_AUTHOR'} eq "[TICKET-AUTHOR]");
    if ($SD::QUERY{'FORM_NOTE_SIGNATURE'} && $SD::ADMIN{'SIGNATURE'}) {
      $NOTE{'MESSAGE'} .= "\n" unless ($NOTE{'MESSAGE'} =~ /\n$/);
      $NOTE{'MESSAGE'} .= $SD::ADMIN{'SIGNATURE'};
    }

    (
      $NOTE{'NID'} = $in{'DB'}->Insert(
        TABLE   => "Notes",
        VALUES  => \%NOTE
      )
    ) || &Error::Error("CP", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");

    if ($Filename) {
      mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'NID'}")
        || &Error::Error("CP", MESSAGE => "Error creating attachment directory. $!");
      chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'NID'}");
      copy($TempFile, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'NID'}/$Filename")
        || &Error::Error("CP", MESSAGE => "Error copying uploaded file. $!");
      chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$NOTE{'NID'}/$Filename");
    }

    $INPUT{'NOTE_RECORD'} = \%NOTE;

    $SD::QUERY{'FORM_NOTE_NOTIFY_AUTHOR'} = 0 if ($SD::QUERY{'FORM_NOTE_PRIVATE'});
    if ($SD::QUERY{'FORM_NOTE_NOTIFY_AUTHOR'}) {
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