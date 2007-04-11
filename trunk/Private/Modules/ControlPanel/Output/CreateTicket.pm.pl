###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/CreateTicket.pm.pl -> CreateTicket skin module           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::CreateTicket;

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
  my %in = (input => undef, error => "", @_);

  my $LANGUAGE = {
    "MISSING" => {
      "SUBJECT"       => qq~<li>You didn't fill in the "Subject" field.~,
      "CATEGORY"      => qq~<li>You didn't fill in the "Category" field.~,
      "AUTHOR"        => qq~<li>You didn't fill in the "Author" field.~,
      "PRIORITY"      => qq~<li>You didn't fill in the "Priority" field.~,
      "SEVERITY"      => qq~<li>You didn't fill in the "Severity" field.~,
      "STATUS"        => qq~<li>You didn't fill in the "Status" field.~,
      "MESSAGE"       => qq~<li>You didn't fill in the "Message" field.~
    },
    "TOOLONG" => {
      "SUBJECT"       => qq~<li>The value for the "Subject" field must be 512 characters or less.~,
      "GUEST_NAME"    => qq~<li>The value for the "Guest Name" field must be 128 chracters or less.~,
      "EMAIL"         => qq~<li>The value for the "Email" field must be 128 characters or less.~
    },
    "INVALID" => {
      "AUTHOR"        => qq~<li>The value you entered for the "Author" field is invalid.~,
      "CATEGORY"      => qq~<li>The value you entered for the "Category" field is invalid.~,
      "OWNED_BY"      => qq~<li>The value you entered for the "Owned By" field is invalid.~
    },
    "ACCESS-DENIED" => qq~<li>You have insufficient rights to add a ticket to the specified category.~,
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form   = HTML::Form->new();

  my $Body = $Dialog->Text(text => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:".$in{'error'});

  $Body .= $Dialog->TextBox(
    name      => "FORM_SUBJECT",
    value     => $SD::QUERY{'FORM_SUBJECT'},
    subject   => "Subject",
    required  => 1
  );

  my @options;
  foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
    push(@options, { value => $category->{'ID'}, text => $category->{'NAME'} });
  }
  
  $Body .= $Dialog->SelectBox(
    name      => "FORM_CATEGORY",
    value     => $SD::QUERY{'FORM_CATEGORY'},
    subject   => "Category",
    required  => 1,
    options   => \@options
  );

  my $value  = qq~<table cellpadding="0" cellspacing="1" border="0" width="100%">~;
     $value .= qq~<tr>~;
     $value .= qq~<td width="180" nowrap colspan="2">~;
     $value .= $Form->Radio(radios => [{ name => "FORM_AUTHOR_TYPE", value => "REG", checked => ($SD::QUERY{'FORM_AUTHOR_TYPE'} eq "REG" ? 1 : 0), label => "Registered Member:" }]);
     $value .= qq~</td>~;
     $value .= qq~<td width="100%">~;
  
  @options = ();
  foreach my $user (@{ $in{'input'}->{'USER_ACCOUNTS'} }) {
    push(@options, { value => $user->{'USERNAME'}, text => $user->{'NAME'}." (".$user->{'USERNAME'}.")" });
  }
  
  $value .= $Form->SelectBox(
    name    => "FORM_AUTHOR",
    options => \@options
  );
  $value .= qq~</td>~;
  $value .= qq~</tr>~;
  $value .= qq~<tr>~;
  $value .= qq~<td width="130" nowrap>~;
  $value .= $Form->Radio(radios => [{ name => "FORM_AUTHOR_TYPE", value => "GUEST", checked => ($SD::QUERY{'FORM_AUTHOR_TYPE'} eq "GUEST" ? 1 : 0), label => "Guest:" }]);
  $value .= qq~</td>~;
  $value .= qq~<td width="50" nowrap><font class="body">Name:</font></td>~;
  $value .= qq~<td width="100%">~;
  $value .= $Form->TextBox(name => "FORM_GUEST_NAME", value => $SD::QUERY{'FORM_GUEST_NAME'});
  $value .= qq~</td>~;
  $value .= qq~</tr>~;
  $value .= qq~<tr>~;
  $value .= qq~<td width="130"></td>~;
  $value .= qq~<td width="50" nowrap><font class="body">Email:</font></td>~;
  $value .= qq~<td width="100%">~;
  $value .= $Form->TextBox(name => "FORM_EMAIL", value => $SD::QUERY{'FORM_EMAIL'});
  $value .= qq~</td>~;
  $value .= qq~</tr>~;
  $value .= qq~</table>~;
  
  $Body .= $Dialog->TextBox(
    value     => $value,
    subject   => "Author",
    required  => 1
  );

  $Body .= $Dialog->TextArea(
    name      => "FORM_MESSAGE",
    value     => $SD::QUERY{'FORM_MESSAGE'},
    subject   => "Message",
    required  => 1,
    rows      => 10
  );

  @options = ();
  foreach my $key (sort keys %{ $GENERAL->{'STATUS'} }) {
    push(@options, { value => $key, text => $GENERAL->{'STATUS'}->{$key} });
  }
  
  $Body .= $Dialog->SelectBox(
    name      => "FORM_STATUS",
    value     => $SD::QUERY{'FORM_STATUS'} || $GENERAL->{'DEFAULT_STATUS'},
    subject   => "Status",
    required  => 1,
    options   => \@options
  );

  @options = ();
  foreach my $key (sort keys %{ $GENERAL->{'PRIORITIES'} }) {
    push(@options, { value => $key, text => $GENERAL->{'PRIORITIES'}->{$key} });
  }
  
  $Body .= $Dialog->SelectBox(
    name      => "FORM_PRIORITY",
    value     => $SD::QUERY{'FORM_PRIORITY'} || $GENERAL->{'DEFAULT_PRIORITY'},
    subject   => "Priority",
    required  => 1,
    options   => \@options
  );

  @options = ();
  foreach my $key (sort keys %{ $GENERAL->{'SEVERITIES'} }) {
    push(@options, { value => $key, text => $GENERAL->{'SEVERITIES'}->{$key} });
  }
  
  $Body .= $Dialog->SelectBox(
    name      => "FORM_SEVERITY",
    value     => $SD::QUERY{'FORM_SEVERITY'} || $GENERAL->{'DEFAULT_SEVERITY'},
    subject   => "Severity",
    required  => 1,
    options   => \@options
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

  $Body .= $Dialog->SelectBox(
    name      => "FORM_OWNED_BY",
    value     => $SD::QUERY{'FORM_OWNED_BY'},
    subject   => "Owned By",
    options   => \@options
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_ATTACHMENT",
    subject   => "Attachment",
    file      => 1
  );

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Add" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "create a ticket").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "DoCreateTicket" },
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

  my $Body = $Dialog->Text(text => "The following ticket has been created:");

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

  my $value;
  if ($in{'input'}->{'RECORD'}->{'AUTHOR'}) {
    $value = $in{'input'}->{'AUTHOR'}->{'NAME'}." (".$in{'input'}->{'AUTHOR'}->{'USERNAME'}.")";
  } elsif ($in{'input'}->{'RECORD'}->{'GUEST_NAME'}) {
    $value = $in{'input'}->{'RECORD'}->{'GUEST_NAME'}." (".$in{'input'}->{'RECORD'}->{'EMAIL'}.")";
  } else {
    $value = $in{'input'}->{'RECORD'}->{'EMAIL'};
  }
  $Body .= $Dialog->TextBox(
    value     => $value,
    subject   => "Author"
  );

  $in{'input'}->{'RECORD'}->{'MESSAGE'} = &Standard::HTMLize($in{'input'}->{'RECORD'}->{'MESSAGE'});
  $in{'input'}->{'RECORD'}->{'MESSAGE'} =~ s/\n/<br>/g;
  $Body .= $Dialog->TextArea(
    value     => $in{'input'}->{'RECORD'}->{'MESSAGE'},
    subject   => "Message"
  );

  $Body .= $Dialog->TextBox(
    value     => $GENERAL->{'STATUS'}->{ $in{'input'}->{'RECORD'}->{'STATUS'} },
    subject   => "Status"
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
    value     => ($in{'input'}->{'RECORD'}->{'OWNED_BY'} ? $in{'input'}->{'STAFF'}->{'NAME'}." (".$in{'input'}->{'STAFF'}->{'USERNAME'}.")" : "--- Nobody ---"),
    subject   => "Owned By"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'ATTACHMENTS'},
    subject   => "Attachment"
  );
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "create a ticket").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;