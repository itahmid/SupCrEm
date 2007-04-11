###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveTickets.pm.pl -> RemoveTickets module                    #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveTickets;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use POSIX;
use strict;

require "ControlPanel/Output/RemoveTickets.pm.pl";

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

  my $Skin = Skin::CP::RemoveTickets->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT, error => $in{'ERROR'});
  
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

  my $Skin = Skin::CP::RemoveTickets->new();

  &Standard::PrintHTMLHeader();
  print $Skin->search(input => \%INPUT);
  
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
    $self->show(DB => $in{'DB'}, ERROR => "MISSING-TID");
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

  my ($Notes, $NotesIndex) = $in{'DB'}->Query(
    TABLE   => "Notes",
    WHERE   => {
      TID => \@TID
    },
    MATCH   => "ANY",
    SORT    => "ID",
    BY      => "A-Z"
  );

  my @Categories;
  foreach my $ticket (@{ $Tickets }) {
    push(@Categories, $ticket->{'CATEGORY'});
  }
  
  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    WHERE   => {
      ID  => \@Categories
    },
    MATCH   => "ANY"
  );

  if ($SD::ADMIN{'LEVEL'} != 100 && $SD::ADMIN{'CATEGORIES'} ne "*") {
    my @categories = split(/,/, $SD::ADMIN{'CATEGORIES'});
    my %categories;
    foreach my $category (@categories) {
      $categories{$category} = 1;
    }
    
    my $error;
    foreach my $category (@{ Categories }) {
      $error = 1 and last unless ($categories{$category});
    }
    
    if ($error) {
      $self->show(DB => $in{'DB'}, ERROR => "ACCESS-DENIED");
    }
  }

  #----------------------------------------------------------------------#
  # Deleting data...                                                     #

  (
    $in{'DB'}->Delete(
      TABLE   => "Tickets",
      KEYS    => \@TID
    )
  ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");
  
  my @NID;
  foreach my $note (@{ $Notes }) {
    push(@NID, $note->{'ID'});
  }
  if (scalar(@NID) >= 1) {
    (
      $in{'DB'}->Delete(
        TABLE   => "Notes",
        KEYS    => \@NID
      )
    ) || &Error::Error("CP", MESSAGE => "Error deleting records. $in{'DB'}->{'ERROR'}");

    foreach my $id (@NID) {
      rmtree("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$id");
    }
  }

  my %INPUT;
  
  $INPUT{'TICKETS'} = $Tickets;
  $INPUT{'NOTES'} = $Notes;
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveTickets->new();

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