###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/ModifyTicket.pm.pl -> ModifyTicket skin module           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::ModifyTicket;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use HTML::Dialog;
use HTML::Form;
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
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #
  
  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();
  
  my ($Body, $Value);
  
  $Body = $Dialog->TextBox(
    name    => "FORM_ID",
    value   => $SD::QUERY{'FORM_ID'},
    subject => "ID"
  );
  
  $Value = $Form->SelectBox(
    name    => "FORM_SUBJECT_RE",
    value   => $SD::QUERY{'FORM_SUBJECT_RE'},
    options => [
      { value => "is", text => "is" },
      { value => "contains", text => "contains" }
    ], class => ""
  );
  $Value .= "&nbsp;".$Form->TextBox(
    name    => "FORM_SUBJECT",
    value   => $SD::QUERY{'FORM_SUBJECT'}
  );
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Subject"
  );

  my @options;
  foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
    push(@options, { value => $category->{'ID'}, text => $category->{'NAME'} });
  }
  $Body .= $Dialog->SelectBox(
    name      => "FORM_CATEGORIES",
    value     => $SD::QUERY{'FORM_CATEGORIES'},
    subject   => "Categories",
    size      => 5,
    multiple  => 1,
    options   => \@options
  );

  @options = ();
  push(@options, { value => "[GUESTS]", text => "Guests" });
  foreach my $user (@{ $in{'input'}->{'USER_ACCOUNTS'} }) {
    push(@options, { value => $user->{'USERNAME'}, text => $user->{'NAME'}." (".$user->{'USERNAME'}.")" });
  }
  $Body .= $Dialog->SelectBox(
    name      => "FORM_AUTHORS",
    value     => $SD::QUERY{'FORM_AUTHORS'},
    subject   => "Authors",
    size      => 5,
    multiple  => 1,
    options   => \@options
  );

  $Value = $Form->SelectBox(
    name    => "FORM_GUEST_NAME_RE",
    value   => $SD::QUERY{'FORM_GUEST_NAME_RE'},
    options => [
      { value => "is", text => "is" },
      { value => "contains", text => "contains" }
    ], class => ""
  );
  $Value .= "&nbsp;".$Form->TextBox(
    name    => "FORM_GUEST_NAME",
    value   => $SD::QUERY{'FORM_GUEST_NAME'}
  );
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Guest Name"
  );

  $Value = $Form->SelectBox(
    name    => "FORM_EMAIL_RE",
    value   => $SD::QUERY{'FORM_EMAIL_RE'},
    options => [
      { value => "is", text => "is" },
      { value => "contains", text => "contains" }
    ], class => ""
  );
  $Value .= "&nbsp;".$Form->TextBox(
    name    => "FORM_EMAIL",
    value   => $SD::QUERY{'FORM_EMAIL'}
  );
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Guest Email"
  );

  @options = (
    { value => "EMAIL", text => "Email" },
    { value => "CP-STAFF", text => "Staff Control Panel" },
    { value => "CP-USER", text => "User Control Panel" }
  );
  $Body .= $Dialog->SelectBox(
    name      => "FORM_DELIVERY_METHODS",
    value     => $SD::QUERY{'FORM_DELIVERY_METHODS'},
    subject   => "Delivery Methods",
    size      => 3,
    multiple  => 1,
    options   => \@options
  );

  @options = (
    { value => "30", text => $GENERAL->{'PRIORITIES'}->{'30'} },
    { value => "40", text => $GENERAL->{'PRIORITIES'}->{'40'} },
    { value => "50", text => $GENERAL->{'PRIORITIES'}->{'50'} },
    { value => "60", text => $GENERAL->{'PRIORITIES'}->{'60'} }
  );
  $Body .= $Dialog->SelectBox(
    name      => "FORM_PRIORITIES",
    value     => $SD::QUERY{'FORM_PRIORITIES'},
    subject   => "Priorities",
    size      => 4,
    multiple  => 1,
    options   => \@options
  );

  @options = (
    { value => "30", text => $GENERAL->{'SEVERITIES'}->{'30'} },
    { value => "40", text => $GENERAL->{'SEVERITIES'}->{'40'} },
    { value => "50", text => $GENERAL->{'SEVERITIES'}->{'50'} },
    { value => "60", text => $GENERAL->{'SEVERITIES'}->{'60'} }
  );
  $Body .= $Dialog->SelectBox(
    name      => "FORM_SEVERITIES",
    value     => $SD::QUERY{'FORM_SEVERITIES'},
    subject   => "Severities",
    size      => 4,
    multiple  => 1,
    options   => \@options
  );

  @options = (
    { value => "30", text => $GENERAL->{'STATUS'}->{'30'} },
    { value => "40", text => $GENERAL->{'STATUS'}->{'40'} },
    { value => "50", text => $GENERAL->{'STATUS'}->{'50'} },
    { value => "60", text => $GENERAL->{'STATUS'}->{'60'} },
    { value => "70", text => $GENERAL->{'STATUS'}->{'70'} }
  );
  $Body .= $Dialog->SelectBox(
    name      => "FORM_STATUS",
    value     => $SD::QUERY{'FORM_STATUS'},
    subject   => "Status",
    size      => 5,
    multiple  => 1,
    options   => \@options
  );

  @options = ();
  push(@options, { value => "[NOBODY]", text => "--- Nobody ---" });
  if ($SD::ADMIN{'LEVEL'} == 100) {
    foreach my $staff (@{ $in{'input'}->{'STAFF_ACCOUNTS'} }) {
      push(@options, { value => $staff->{'USERNAME'}, text => $staff->{'NAME'}." (".$staff->{'USERNAME'}.")" });
    }
  } else {
    push(@options, { value => $SD::ADMIN{'USERNAME'}, text => $SD::ADMIN{'NAME'}." (".$SD::ADMIN{'USERNAME'}.")" });
  }
  $Body .= $Dialog->SelectBox(
    name      => "FORM_OWNED_BY",
    value     => $SD::QUERY{'FORM_OWNED_BY'},
    subject   => "Owned By",
    size      => ($SD::ADMIN{'LEVEL'} == 100 ? 5 : 2),
    multiple  => 1,
    options   => \@options
  );
  
  $Value = $Form->SelectBox(
    name    => "FORM_CREATE_SECOND_OPER",
    value   => $SD::QUERY{'FORM_CREATE_SECOND_OPER'},
    options => [
      { value => "more", text => "more" },
      { value => "less", text => "less" }
    ], class => ""
  );
  $Value .= " than ".$Form->TextBox(
    name    => "FORM_CREATE_SECOND",
    value   => $SD::QUERY{'FORM_CREATE_SECOND'},
    class   => ""
  );
  $Value .= " days.";
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Created"
  );

  $Value = $Form->SelectBox(
    name    => "FORM_UPDATE_SECOND_OPER",
    value   => $SD::QUERY{'FORM_UPDATE_SECOND_OPER'},
    options => [
      { value => "more", text => "more" },
      { value => "less", text => "less" }
    ], class => ""
  );
  $Value .= " than ".$Form->TextBox(
    name    => "FORM_UPDATE_SECOND",
    value   => $SD::QUERY{'FORM_UPDATE_SECOND'},
    class   => ""
  );
  $Value .= " days.";
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Updated"
  );

  $Body .= $Dialog->SelectBox(
    name    => "FORM_BOOLEAN",
    value   => $SD::QUERY{'FORM_BOOLEAN'} || "AND",
    subject => "Boolean",
    options => [
      { value => "OR", text => "OR" },
      { value => "AND", text => "AND" }
    ]
  );

  $Value = $Form->SelectBox(
    name    => "FORM_SORT_FIELD",
    value   => $SD::QUERY{'FORM_SORT_FIELD'},
    options => [
      { value => "ID", text => "ID" },
      { value => "SUBJECT", text => "Subject" },
      { value => "CATEGORY", text => "Category" },
      { value => "AUTHOR", text => "Author" },
      { value => "PRIORITY", text => "Priority" },
      { value => "SEVERITY", text => "Severity" },
      { value => "STATUS", text => "Status" },
      { value => "OWNED_BY", text => "Owned By" },
      { value => "CREATE_SECOND", text => "Creation Date" },
      { value => "UPDATE_SECOND", text => "Update Date" }
    ], class => ""
  );
  $Value .= "&nbsp;".$Form->SelectBox(
    name    => "FORM_SORT_BY",
    value   => $SD::QUERY{'FORM_SORT_BY'},
    options => [
      { value => "A-Z", text => "Ascending" },
      { value => "Z-A", text => "Descending" }
    ], class => ""
  );
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Sort"
  );

  $Body .= $Dialog->TextBox(
    name    => "FORM_TICKETS_PER_PAGE",
    value   => $SD::QUERY{'FORM_TICKETS_PER_PAGE'} || 10,
    subject => "Tickets Per Page"
  );

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify/view/add to a ticket").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "SearchModifyTicket" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# search subroutine
sub search {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body = $Dialog->SmallHeader(
    titles => [
      { text => "", width => 1 },
      { text => "id", width => 1, nowrap => 1 },
      { text => "subject", width => "100%" },
      { text => "notes", width => 40, nowrap => 1 },
      { text => "status", width => 80, nowrap => 1 },
      { text => "author", width => 180, nowrap => 1 },
      { text => "owned by", width => 180, nowrap => 1 },
      { text => "category", width => 180, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Modify/View/Add To a Ticket", colspan => 8);
  
  foreach my $ticket (@{ $in{'input'}->{'TICKETS'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "TID", value => $ticket->{'ID'} }
      ]
    );
    $fields[1] = $ticket->{'ID'};
    $fields[2] = $ticket->{'SUBJECT'};
    $fields[3] = $ticket->{'NOTES'};
    $fields[4] = $GENERAL->{'STATUS'}->{ $ticket->{'STATUS'} };
    
    if ($ticket->{'AUTHOR'}) {
      $fields[5]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$ticket->{'AUTHOR'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
      $fields[5] .= $in{'input'}->{'USER_ACCOUNTS'}->[$in{'input'}->{'USER_ACCOUNTS_IX'}->{$ticket->{'AUTHOR'}}]->{'NAME'}." (".$ticket->{'AUTHOR'}.")";
      $fields[5] .= qq~</a>~;
    } elsif ($ticket->{'GUEST_NAME'}) {
      $fields[5] = $ticket->{'GUEST_NAME'}." (".$ticket->{'EMAIL'}.")";
    } else {
      $fields[5] = $ticket->{'EMAIL'}
    }
    
    if ($ticket->{'OWNED_BY'}) {
      $fields[6] = $in{'input'}->{'STAFF_ACCOUNTS'}->[$in{'input'}->{'STAFF_ACCOUNTS_IX'}->{$ticket->{'OWNED_BY'}}]->{'NAME'}." (".$ticket->{'OWNED_BY'}.")";
    } else {
      $fields[6] = "--- Nobody ---";
    }
    
    $fields[7] = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$ticket->{'CATEGORY'}}]->{'NAME'};
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 8);

  $value  = qq~<table cellpadding="0" cellspacing="0" width="100%" border="0">~;
  $value .= qq~<tr><td align="right">~;
  $value .= qq~<font class="row"><small>~;

  my $QueryString;
  foreach my $key (keys %SD::QUERY) {
    $QueryString .= "$key=$SD::QUERY{$key}&" unless ($key eq "Page");
  }
  
  $value .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?~.$QueryString.qq~Page=~.($in{'input'}->{'PAGE'} - 1).qq~">~ unless ($in{'input'}->{'PAGE'} == 1);
  $value .= qq~&lt; Prev~;
  $value .= qq~</a>~ unless ($in{'input'}->{'PAGE'} == 1);
  $value .= qq~ | ~;
  
  for (my $h = 1; $h <= $in{'input'}->{'TOTAL_PAGES'}; $h++) {
    if ($h == $in{'input'}->{'PAGE'}) {
      $value .= $h." ";
    } else {
      $value .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?~.$QueryString.qq~Page=$h">$h</a> ~;
    }
  }
  
  $value .= qq~| ~;
  $value .= qq~<a href="$SYSTEM->{'SCRIPT_URL'}?~.$QueryString.qq~Page=~.($in{'input'}->{'PAGE'} + 1).qq~">~ unless ($in{'input'}->{'PAGE'} == $in{'input'}->{'TOTAL_PAGES'});
  $value .= qq~Next &gt;~;
  $value .= qq~</a>~ unless ($in{'input'}->{'PAGE'} == $in{'input'}->{'TOTAL_PAGES'});
  $value .= qq~</small></font></td></tr></table>~;
  
  $Body .= $Dialog->Row(fields => $value, colspan => 8);

  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "ViewModifyTicket" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (input => undef, error => "", @_);

  my $LANGUAGE = {
    "MISSING" => {
      "SUBJECT"       => qq~<li>You didn't fill in the "Subject" field.~,
      "CATEGORY"      => qq~<li>You didn't fill in the "Category" field.~,
      "PRIORITY"      => qq~<li>You didn't fill in the "Priority" field.~,
      "SEVERITY"      => qq~<li>You didn't fill in the "Severity" field.~,
      "STATUS"        => qq~<li>You didn't fill in the "Status" field.~,
      
      "NOTE_SUBJECT"  => qq~<li>You didn't fill in the "Note Subject" field.~,
      "NOTE_MESSAGE"  => qq~<li>You didn't fill in the "Note Message" field.~,
      "NOTE_AUTHOR"   => qq~<li>You didn't fill in the "Note Author" field.~
    },
    "TOOLONG" => {
      "SUBJECT"       => qq~<li>The value for the "Subject" field must be 512 characters or less.~,
      "NOTE_SUBJECT"  => qq~<li>The value for the "Note Subject" field must be 512 characters or less.~
    },
    "INVALID" => {
      "CATEGORY"      => qq~<li>The value you entered for the "Category" field is invalid.~,
      "OWNED_BY"      => qq~<li>The value you entered for the "Owned By" field is invalid.~,
      "NOTE_AUTHOR"   => qq~<li>The value you entered for the "Note Author" field is invalid.~
    },
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Section;
  
  if ($in{'error'}) {
    $Section = $Dialog->Text(text => $in{'error'});
  }

  $Section .= $Dialog->TextBox(
    value     => $in{'input'}->{'TICKET'}->{'ID'},
    subject   => "ID"
  );

  $Section .= $Dialog->TextBox(
    name      => "FORM_SUBJECT",
    value     => $SD::QUERY{'FORM_SUBJECT'} || $in{'input'}->{'TICKET'}->{'SUBJECT'},
    subject   => "Subject",
    required  => 1
  );

  my @options;
  foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
    push(@options, { value => $category->{'ID'}, text => $category->{'NAME'} });
  }
  $Section .= $Dialog->SelectBox(
    name      => "FORM_CATEGORY",
    value     => $SD::QUERY{'FORM_CATEGORY'} || $in{'input'}->{'TICKET'}->{'CATEGORY'},
    subject   => "Category",
    options   => \@options,
    required  => 1
  );

  my $Value;
  if ($in{'input'}->{'TICKET'}->{'AUTHOR'}) {
    $Value = $in{'input'}->{'USER_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'}.")";
  } elsif ($in{'input'}->{'TICKET'}->{'GUEST_NAME'}) {
    $Value = $in{'input'}->{'TICKET'}->{'GUEST_NAME'}." (".$in{'input'}->{'TICKET'}->{'EMAIL'}.")";
  } else {
    $Value = $in{'input'}->{'TICKET'}->{'EMAIL'};
  }
  $Section .= $Dialog->TextBox(
    value     => $Value,
    subject   => "Author"
  );

  if ($in{'input'}->{'TICKET'}->{'DELIVERY_METHOD'} eq "CP-STAFF") {
    $Value = "Staff Control Panel";
  } elsif ($in{'input'}->{'TICKET'}->{'DELIVERY_METHOD'} eq "CP-USER") {
    $Value = "User Control Panel";
  } elsif ($in{'input'}->{'TICKET'}->{'DELIVERY_METHOD'} eq "EMAIL") {
    $Value = "Email";
  }
  $Section .= $Dialog->TextBox(
    value   => $Value,
    subject => "Delivery Method"
  );

  @options = ();
  foreach my $key (keys %{ $GENERAL->{'PRIORITIES'} }) {
    push(@options, { value => $key, text => $GENERAL->{'PRIORITIES'}->{$key} });
  }
  $Section .= $Dialog->SelectBox(
    name      => "FORM_PRIORITY",
    value     => $SD::QUERY{'FORM_PRIORITY'} || $in{'input'}->{'TICKET'}->{'PRIORITY'},
    subject   => "Priority",
    options   => \@options,
    required  => 1
  );

  @options = ();
  foreach my $key (keys %{ $GENERAL->{'SEVERITIES'} }) {
    push(@options, { value => $key, text => $GENERAL->{'SEVERITIES'}->{$key} });
  }
  $Section .= $Dialog->SelectBox(
    name      => "FORM_SEVERITY",
    value     => $SD::QUERY{'FORM_SEVERITY'} || $in{'input'}->{'TICKET'}->{'SEVERITY'},
    subject   => "Severity",
    options   => \@options,
    required  => 1
  );

  @options = ();
  foreach my $key (sort keys %{ $GENERAL->{'STATUS'} }) {
    push(@options, { value => $key, text => $GENERAL->{'STATUS'}->{$key} });
  }
  $Section .= $Dialog->SelectBox(
    name      => "FORM_STATUS",
    value     => $SD::QUERY{'FORM_STATUS'} || $in{'input'}->{'TICKET'}->{'STATUS'},
    subject   => "Status",
    options   => \@options,
    required  => 1
  );

  @options = ();
  push(@options, { value => "", text => "--- Nobody ---" });
  if ($SD::ADMIN{'LEVEL'} == 100) {
    foreach my $staff (@{ $in{'input'}->{'STAFF_ACCOUNTS'} }) {
      push(@options, { value => $staff->{'USERNAME'}, text => $staff->{'NAME'}." (".$staff->{'USERNAME'}.")" });
    }
  } else {
    push(@options, { value => $SD::ADMIN{'USERNAME'}, text => $SD::ADMIN{'NAME'}." (".$SD::ADMIN{'USERNAME'}.")" });
  }
  $Section .= $Dialog->SelectBox(
    name      => "FORM_OWNED_BY",
    value     => $SD::QUERY{'FORM_OWNED_BY'} || $in{'input'}->{'TICKET'}->{'OWNED_BY'},
    subject   => "Owned By",
    options   => \@options
  );

  $Section .= $Dialog->TextBox(
    value   => $in{'input'}->{'TICKET'}->{'CREATE_DATE'}." at ".$in{'input'}->{'TICKET'}->{'CREATE_TIME'},
    subject => "Created"
  );
  
  $Section .= $Dialog->TextBox(
    value   => $in{'input'}->{'TICKET'}->{'UPDATE_DATE'}." at ".$in{'input'}->{'TICKET'}->{'UPDATE_TIME'},
    subject => "Last Updated"
  );

  $Section .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Modify" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  my $Body  = $Dialog->SmallHeader(titles => "modify/view/add to a ticket");
     $Body .= $Dialog->LargeHeader(title => "Ticket Information");
     $Body .= $Dialog->Dialog(body => $Section);
     $Body .= $Dialog->LargeHeader(title => "Notes");

  foreach my $note (@{ $in{'input'}->{'NOTES'} }) {
    my ($subject, $author);
    if ($note->{'AUTHOR_TYPE'} eq "USER") {
      if ($in{'input'}->{'TICKET'}->{'AUTHOR'}) {
        $subject = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$in{'input'}->{'TICKET'}->{'AUTHOR'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">$in{'input'}->{'USER_ACCOUNT'}->{'NAME'}</a>~;
        $author = $in{'input'}->{'USER_ACCOUNT'}->{'NAME'};
      } elsif ($in{'input'}->{'TICKET'}->{'GUEST_NAME'}) {
        $subject = qq~<a href="mailto:$in{'input'}->{'TICKET'}->{'EMAIL'}">$in{'input'}->{'TICKET'}->{'GUEST_NAME'}</a>~;
        $author = $in{'input'}->{'TICKET'}->{'GUEST_NAME'};
      } else {
        $subject = qq~<a href="mailto:$in{'input'}->{'TICKET'}->{'EMAIL'}">$in{'input'}->{'TICKET'}->{'EMAIL'}</a>~;
        $author = $in{'input'}->{'TICKET'}->{'EMAIL'};
      }
    } else {
      $subject  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=StaffProfile&USERNAME=$note->{'AUTHOR'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
      $subject .= $in{'input'}->{'STAFF_ACCOUNTS'}->[$in{'input'}->{'STAFF_ACCOUNTS_IX'}->{$note->{'AUTHOR'}}]->{'NAME'};
      $subject .= qq~</a> <img src="http://www.obsidian-scripts.com/images/offsite/admin.gif" border="0">~;
      $author = $in{'input'}->{'STAFF_ACCOUNTS'}->[$in{'input'}->{'STAFF_ACCOUNTS_IX'}->{$note->{'AUTHOR'}}]->{'NAME'};
    }
    
    my $subsubject  = $note->{'CREATE_DATE'}." at ".$note->{'CREATE_TIME'};
    
    my $html;
    if ($note->{'ATTACHMENTS'}) {
      $subsubject .= "<p><b>Attachments:</b><br>";
      foreach my $attachment (split(/,/, $note->{'ATTACHMENTS'})) {
        $subsubject .= qq~<a href="$SYSTEM->{'PUBLIC_URL'}/Attachments/$note->{'ID'}/$attachment" target="_blank">$attachment</a><br>~;
        $html = 1 if ($attachment eq "message.html");
      }
    }
    
    $subsubject .= "<p>";
    if ($note->{'DELIVERY_METHOD'} eq "CP-STAFF") {
      $subsubject .= "Staff Control Panel";
    } elsif ($note->{'DELIVERY_METHOD'} eq "CP-USER") {
      $subsubject .= "User Control Panel";
    } elsif ($note->{'DELIVERY_METHOD'} eq "EMAIL") {
      $subsubject .= "Email";
    }
    $subsubject .= "<br>Private" if ($note->{'PRIVATE'});
    $subsubject .= qq~<p><a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=ModifyNote&NID=$note->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">EDIT</a>~;
    $subsubject .= qq~ | <a href="javascript:Reply('$author', '~;

    $note->{'MESSAGE'} = &Standard::HTMLize($note->{'MESSAGE'});
    
    my $message = $note->{'MESSAGE'};
       $message =~ s/\n/\\n/g;
       $message =~ s/\&/\\\&/g;
    $subsubject .= $message.qq~')">REPLY</a>~;
    
    unless ($note->{'ID'} == $in{'input'}->{'NOTES'}->[0]->{'ID'}) {
      $subsubject .= qq~ | <a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=DoRemoveNote&NID=$note->{'ID'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">REMOVE</a>~;
    }
    
    $note->{'MESSAGE'} =~ s/\n/<br>/g;
    my $section .= $Dialog->TextArea(
      value         => "<b>".$note->{'SUBJECT'}."</b>".($html && $GENERAL->{'SHOW_HTML_MESSAGE'} ? qq~<br><iframe src="$SYSTEM->{'PUBLIC_URL'}/Attachments/$note->{'ID'}/message.html" rows="10" marginwidth="2" marginheight="2" style="width: 100%"></iframe>~ : "<p>".$note->{'MESSAGE'}),
      subject       => $subject,
      "sub-subject" => $subsubject
    );
    $Body .= $Dialog->Dialog(body => $section);
  }

  my $Subject = $in{'input'}->{'TICKET'}->{'SUBJECT'};
     $Subject =~ s/^Re:\s*//ig;
     $Subject = "Re: ".$Subject;
  $Section = $Dialog->TextBox(
    name      => "FORM_NOTE_SUBJECT",
    value     => $SD::QUERY{'FORM_NOTE_SUBJECT'} || $Subject,
    subject   => "Subject",
    required  => 1
  );
  
  @options = ();
  push(@options, { value => "[TICKET-AUTHOR]", text => "--- Ticket Author ---" });
  if ($SD::ADMIN{'LEVEL'} == 100) {
    foreach my $staff (@{ $in{'input'}->{'STAFF_ACCOUNTS'} }) {
      push(@options, { value => $staff->{'USERNAME'}, text => $staff->{'NAME'}." (".$staff->{'USERNAME'}.")" });
    }
  } else {
    push(@options, { value => $SD::ADMIN{'USERNAME'}, text => $SD::ADMIN{'NAME'}." (".$SD::ADMIN{'USERNAME'}.")" });
  }
  $Section .= $Dialog->SelectBox(
    name      => "FORM_NOTE_AUTHOR",
    value     => $SD::QUERY{'FORM_NOTE_AUTHOR'} || $SD::ADMIN{'USERNAME'},
    subject   => "Author",
    required  => 1,
    options   => \@options,
    extra     => "onChange=\"ChangeAuthor()\""
  );
  
  $Section .= $Dialog->TextArea(
    name      => "FORM_NOTE_MESSAGE",
    value     => $SD::QUERY{'FORM_NOTE_MESSAGE'},
    subject   => "Message",
    rows      => 10,
    required  => 1
  );
  
  $Section .= $Dialog->TextBox(
    name      => "FORM_NOTE_ATTACHMENT",
    subject   => "Attachment",
    file      => 1
  );
  
  $Section .= $Dialog->CheckBox(
    name        => "FORM_NOTE_SIGNATURE",
    value       => $SD::QUERY{'FORM_NOTE_SIGNATURE'},
    checkboxes  => [{ value => "1", label => "Add signature?" }]
  );
  
  $Section .= $Dialog->CheckBox(
    name        => "FORM_NOTE_PRIVATE",
    value       => $SD::QUERY{'FORM_NOTE_PRIVATE'},
    checkboxes  => [{ value => "1", label => "Private?", extra => "onClick=\"ChangePrivate()\"" }]
  );
  $Section .= $Dialog->CheckBox(
    name        => "FORM_NOTE_NOTIFY_AUTHOR",
    value       => $SD::QUERY{'FORM_NOTE_NOTIFY_AUTHOR'},
    checkboxes  => [{ value => "1", label => "Notify ticket author?" }]
  );
  
  $Section .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Add", extra => "onClick=\"form.FORM_NOTE.value = '1';\"" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body .= $Dialog->LargeHeader(title => "Add Note");
  $Body .= $Dialog->Dialog(body => $Section);

  my $Script = <<HTML;
<script language="JavaScript">
  <!--
  function Reply(author, message) {
    var lines = message.split("\\n");
    var field = form.FORM_NOTE_MESSAGE;

    field.value = author + " wrote\\n";
    for (var h = 0; h <= lines.length - 1; h++) {
      field.value = field.value + "> " + lines[h] + "\\n";
    }
    field.value = field.value + "\\n";
    field.focus();
    
    if (field.createTextRange) {
      var r = field.createTextRange();
      r.moveStart('character', field.value.length);
      r.collapse();
      r.select();
    }
  }
  function ChangeAuthor() {
    var author = form.FORM_NOTE_AUTHOR;
    var signature = form.FORM_NOTE_SIGNATURE;
    var private = form.FORM_NOTE_PRIVATE;
    var notify = form.FORM_NOTE_NOTIFY_AUTHOR;
    
    if (author.value == "[TICKET-AUTHOR]") {
      signature.checked = false;
      signature.disabled = true;
      private.checked = false;
      private.disabled = true;
      notify.disabled = false;
    } else {
      private.disabled = false;
      signature.disabled = false;
    }
  }
  function ChangePrivate() {
    var private = form.FORM_NOTE_PRIVATE;
    var notify = form.FORM_NOTE_NOTIFY_AUTHOR;
    
    if (private.checked) {
      notify.checked = false;
      notify.disabled = true;
    } else {
      notify.disabled = false;
    }
  }
  //-->
</script>
HTML

  $Body = $Dialog->Body($Body);
  $Body = $Script.$Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "FORM_NOTE", value => "" },
      { name => "TID", value => $SD::QUERY{'TID'} },
      { name => "CP", value => "1" },
      { name => "action", value => "DoModifyTicket" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ],
    extra   => qq~enctype="multipart/form-data"~
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The following ticket has been modified:");

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'TID'},
    subject   => "ID"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'SUBJECT'},
    subject   => "Subject"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'CATEGORY'}->{'NAME'},
    subject   => "Category"
  );

  my $Value;
  if ($in{'input'}->{'TICKET'}->{'AUTHOR'}) {
    $Value = $in{'input'}->{'USER_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'}.")";
  } elsif ($in{'input'}->{'TICKET'}->{'GUEST_NAME'}) {
    $Value = $in{'input'}->{'TICKET'}->{'GUEST_NAME'}." (".$in{'input'}->{'TICKET'}->{'EMAIL'}.")";
  } else {
    $Value = $in{'input'}->{'TICKET'}->{'EMAIL'};
  }
  $Body .= $Dialog->TextBox(
    value     => $Value,
    subject   => "Author"
  );

  if ($in{'input'}->{'TICKET'}->{'DELIVERY_METHOD'} eq "CP-STAFF") {
    $Value = "Staff Control Panel";
  } elsif ($in{'input'}->{'TICKET'}->{'DELIVERY_METHOD'} eq "CP-USER") {
    $Value = "User Control Panel";
  } elsif ($in{'input'}->{'TICKET'}->{'DELIVERY_METHOD'} eq "EMAIL") {
    $Value = "Email";
  }
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Delivery Method"
  );

  $Body .= $Dialog->TextBox(
    value     => $GENERAL->{'PRIORITIES'}->{ $in{'input'}->{'RECORD'}->{'PRIORITY'} },
    subject   => "Priority"
  );

  $Body .= $Dialog->TextBox(
    value     => $GENERAL->{'SEVERITIES'}->{ $in{'input'}->{'RECORD'}->{'SEVERITY'} },
    subject   => "Severity"
  );

  $Body .= $Dialog->TextBox(
    value     => $GENERAL->{'STATUS'}->{ $in{'input'}->{'RECORD'}->{'STATUS'} },
    subject   => "Status"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'RECORD'}->{'OWNED_BY'} ? $in{'input'}->{'STAFF_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'STAFF_ACCOUNT'}->{'USERNAME'}.")" : "--- Nobody ---"),
    subject   => "Owned By"
  );

  if ($in{'input'}->{'NOTE_RECORD'}) {
    $Body .= $Dialog->Text(text => "<br>In addition, the following note has been created:");
    
    $Body .= $Dialog->TextBox(
      value   => $in{'input'}->{'NOTE_RECORD'}->{'SUBJECT'},
      subject => "Subject"
    );

    if ($in{'input'}->{'NOTE_RECORD'}->{'AUTHOR_TYPE'} eq "USER") {
      if ($in{'input'}->{'TICKET'}->{'AUTHOR'}) {
        $Value = $in{'input'}->{'USER_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'}.")";
      } elsif ($in{'input'}->{'TICKET'}->{'GUEST_NAME'}) {
        $Value = $in{'input'}->{'TICKET'}->{'GUEST_NAME'}." (".$in{'input'}->{'TICKET'}->{'EMAIL'}.")";
      } else {
        $Value = $in{'input'}->{'TICKET'}->{'EMAIL'};
      }
    } else {
      $Value = $in{'input'}->{'NOTE_STAFF_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'NOTE_STAFF_ACCOUNT'}->{'USERNAME'}.")";
    }
    $Body .= $Dialog->TextBox(
      value   => $Value,
      subject => "Author"
    );

    unless ($GENERAL->{'HTML_IN_USER_EMAILS'}) {
      $in{'input'}->{'NOTE_RECORD'}->{'MESSAGE'} = &Standard::HTMLize($in{'input'}->{'NOTE_RECORD'}->{'MESSAGE'});
      $in{'input'}->{'NOTE_RECORD'}->{'MESSAGE'} =~ s/\n/<br>/g;
    }
    $Body .= $Dialog->TextArea(
      value   => $in{'input'}->{'NOTE_RECORD'}->{'MESSAGE'},
      subject => "Message"
    );
    
    $Body .= $Dialog->TextBox(
      value   => $in{'input'}->{'NOTE_RECORD'}->{'ATTACHMENTS'},
      subject => "Attachment"
    );
  }

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a ticket").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# email subroutine
sub email {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my %FIELDS;
  
  $FIELDS{'account'}      = $in{'input'}->{'USER_ACCOUNT'};
  $FIELDS{'ticket'}       = $in{'input'}->{'TICKET'};
  $FIELDS{'category'}     = $in{'input'}->{'CATEGORY'};
  $FIELDS{'record'}       = $in{'input'}->{'NOTE_RECORD'};
  $FIELDS{'staffaccount'} = $in{'input'}->{'NOTE_STAFF_ACCOUNT'};

  #----------------------------------------------------------------------#
  # Printing email...                                                    #

  my $LANGUAGE = &Standard::GetLanguage("ProcessEmail");

  my %Return;

  $Return{'MESSAGE'} = &Standard::Substitute(
    INPUT     => "Emails/CPModifyTicket-Note-User.txt",
    STANDARD  => 1,
    FIELDS    => \%FIELDS
  );
  $Return{'TO'} = $in{'input'}->{'TICKET'}->{'EMAIL'};
  $Return{'FROM'} = "\"".$in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'}."\" <".$in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'}.">";
  $Return{'SUBJECT'} = "[SD-".$in{'input'}->{'TICKET'}->{'ID'}."] ".$in{'input'}->{'NOTE_RECORD'}->{'SUBJECT'};
  $Return{'HEADERS'}{'Content-Type'} = "text/plain" unless ($GENERAL->{'HTML_IN_USER_EMAILS'});

  $Return{'ATTACHMENTS'} = ["$SYSTEM->{'PUBLIC_PATH'}/Attachments/$in{'input'}->{'NOTE_RECORD'}->{'ID'}/$in{'input'}->{'NOTE_RECORD'}->{'ATTACHMENTS'}"] if ($in{'input'}->{'NOTE_RECORD'}->{'ATTACHMENTS'});
  
  return %Return;
}

1;