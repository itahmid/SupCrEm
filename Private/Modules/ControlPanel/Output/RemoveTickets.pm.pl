###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/RemoveTickets.pm.pl -> RemoveTickets skin module         #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::RemoveTickets;

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
  $Body = $Dialog->TextBox(
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
  $Body = $Dialog->SmallHeader(titles => "remove tickets").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "SearchRemoveTickets" },
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
  
  $Body .= $Dialog->LargeHeader(title => "Remove Tickets", colspan => 8);
  
  foreach my $ticket (@{ $in{'input'}->{'TICKETS'} }) {
    my @fields;
    $fields[0] = $Form->CheckBox(
      checkboxes  => [
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
      { type => "button", value => "Select All", extra => "onClick=\"checkAll()\"" },
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

  my $Script  = qq~<script language="JavaScript">\n~;
     $Script .= qq~  <!--\n~;
     $Script .= qq~  function checkAll() {\n~;

  if (scalar(@{ $in{'input'}->{'TICKETS'} }) == 1) {
    $Script .= qq~    document.form.TID.checked = true;\n~;
  } elsif (scalar(@{ $in{'input'}->{'TICKETS'} }) > 1) {
    $Script .= qq~    for (var h = 0; h <= ~.(scalar(@{ $in{'input'}->{'TICKETS'} }) - 1).qq~; h++) {\n~;
    $Script .= qq~      document.form.TID[h].checked = true;\n~;
    $Script .= qq~    }\n~;
  }

  $Script .= qq~  }\n~;
  $Script .= qq~  //-->\n~;
  $Script .= qq~</script>\n~;

  $Body = $Script.$Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "DoRemoveTickets" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
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

  my $Body = $Dialog->Text(text => "The selected tickets have been removed.");

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "remove tickets").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;