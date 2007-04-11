###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/ModifyStaff.pm.pl -> ModifyStaff skin module             #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::ModifyStaff;

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

  my $Body = $Dialog->SmallHeader(
    titles => [
      { text => "", width => 1 },
      { text => "name", width => "100%" },
      { text => "username", width => 250, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Modify a Staff Account", colspan => 3);
  
  foreach my $staff (@{ $in{'input'}->{'STAFF_ACCOUNTS'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "USERNAME", value => $staff->{'USERNAME'} }
      ]
    );

    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=StaffProfile&USERNAME=$staff->{'USERNAME'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $staff->{'NAME'};
    $fields[1] .= qq~</a>~;

    $fields[2] = $staff->{'USERNAME'};
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 3);
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "ViewModifyStaff" },
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
      "USERNAME"      => qq~<li>You didn't fill in the "Username" field.~,
      "PASSWORD"      => qq~<li>You didn't fill in the "Password" field.~,
      "NAME"          => qq~<li>You didn't fill in the "Name" field.~,
      "EMAIL"         => qq~<li>You didn't fill in the "Email" field.~,
      "STATUS"        => qq~<li>You didn't fill in the "Status" field.~,
      "LEVEL"         => qq~<li>You didn't fill in the "Level" field.~
    },
    "TOOLONG" => {
      "USERNAME"      => qq~<li>The value for the "Username" field must be 48 characters or less.~,
      "PASSWORD"      => qq~<li>The value for the "Password" field must be 64 characters or less.~,
      "NAME"          => qq~<li>The value for the "Name" field must be 128 characters or less.~,
      "EMAIL"         => qq~<li>The value for the "Email" field must be 128 characters or less.~,
      "SIGNATURE"     => qq~<li>The value for the "Signature" field must be 512 characters or less.~
    },
    "ALREADYEXISTS" => {
      "USERNAME"      => qq~<li>The value you entered for the "Username" field already exists.~
    },
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body = $Dialog->Text(text => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:".$in{'error'});

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'STAFF_ACCOUNT'}->{'USERNAME'},
    subject   => "Username"
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_PASSWORD",
    value     => $SD::QUERY{'FORM_PASSWORD'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'PASSWORD'},
    subject   => "Password",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_NAME",
    value     => $SD::QUERY{'FORM_NAME'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'NAME'},
    subject   => "Name",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_EMAIL",
    value     => $SD::QUERY{'FORM_EMAIL'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'EMAIL'},
    subject   => "Email",
    required  => 1
  );
  
  $Body .= $Dialog->Radio(
    name      => "FORM_STATUS",
    value     => $SD::QUERY{'FORM_STATUS'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'STATUS'},
    subject   => "Status",
    required  => 1,
    radios    => [
      { value => "30", label => "Inactive" },
      { value => "50", label => "Active" }
    ], join => "&nbsp;"
  );

  $Body .= $Dialog->Radio(
    name      => "FORM_LEVEL",
    value     => $SD::QUERY{'FORM_LEVEL'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'LEVEL'},
    subject   => "Level",
    required  => 1,
    radios    => [
      { value => "100", label => "Administrator" },
      { value => "70", label => "Support Staff" },
    ], join => "&nbsp;"
  );

  my @value = $SD::CGI->param('FORM_CATEGORIES');
     @value = split(/,/, $in{'input'}->{'STAFF_ACCOUNT'}->{'CATEGORIES'}) if (scalar(@value) < 1);
  my %values;
  foreach my $value (@value) {
    $values{$value} = 1;
  }

  my @options;
  foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
    push(@options, { value => $category->{'ID'}, text => $category->{'NAME'}, selected => ($values{$category->{'ID'}} ? 1 : 0) });
  }

  my $value = qq~<table cellpadding="3" cellspacing="0" border="0" width="100%"><tr><td>~;
  
  my $CategoriesAll = $SD::QUERY{'FORM_CATEGORIES_ALL'};
     $CategoriesAll = 1 if ($SD::QUERY{'FORM_CATEGORIES_ALL'} eq "" && $in{'input'}->{'STAFF_ACCOUNT'}->{'CATEGORIES'} eq "*");
  $value .= $Form->CheckBox(
    checkboxes  => [
      { name => "FORM_CATEGORIES_ALL", value => "1", checked => ($CategoriesAll ? 1 : 0), label => "All Categories?" }
    ]
  );
  $value .= "</td></tr><tr><td>";
  $value .= $Form->SelectBox(
    name      => "FORM_CATEGORIES",
    multiple  => 1,
    size      => 4,
    options   => \@options
  );
  $value .= "</td></tr></table>";

  $Body .= $Dialog->TextBox(
    value     => $value,
    subject   => "Categories"
  );

  $Body .= $Dialog->TextArea(
    name    => "FORM_SIGNATURE",
    value   => $SD::QUERY{'FORM_SIGNATURE'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'SIGNATURE'},
    subject => "Signature",
    rows    => 3
  );
  
  $Body .= $Dialog->CheckBox(
    name        => "FORM_NOTIFY_NEW_TICKETS",
    value       => $SD::QUERY{'FORM_NOTIFY_NEW_TICKETS'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'NOTIFY_NEW_TICKETS'},
    subject     => "Email Notifications",
    checkboxes  => [{ value => "1", label => "New tickets" }]
  );

  $Body .= $Dialog->CheckBox(
    name        => "FORM_NOTIFY_NEW_NOTES_UNOWNED",
    value       => $SD::QUERY{'FORM_NOTIFY_NEW_NOTES_UNOWNED'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'NOTIFY_NEW_NOTES_UNOWNED'},
    checkboxes  => [{ value => "1", label => "New notes in unowned tickets" }]
  );

  $Body .= $Dialog->CheckBox(
    name        => "FORM_NOTIFY_NEW_NOTES_OWNED",
    value       => $SD::QUERY{'FORM_NOTIFY_NEW_NOTES_OWNED'} || $in{'input'}->{'STAFF_ACCOUNT'}->{'NOTIFY_NEW_NOTES_OWNED'},
    checkboxes  => [{ value => "1", label => "New notes in tickets owned by you" }]
  );

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Modify" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a staff account").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "USERNAME", value => $in{'input'}->{'STAFF_ACCOUNT'}->{'USERNAME'} },
      { name => "CP", value => "1" },
      { name => "action", value => "DoModifyStaff" },
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

  my $Body = $Dialog->Text(text => "The following staff account has been modified:");

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'USERNAME'},
    subject   => "Username"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'PASSWORD'},
    subject   => "Password"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'NAME'},
    subject   => "Name"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'EMAIL'},
    subject   => "Email"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'RECORD'}->{'STATUS'} == 50 ? "Active" : "Inactive"),
    subject   => "Status"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'RECORD'}->{'LEVEL'} == 100 ? "Administrator" : "Support Staff"),
    subject   => "Level"
  );

  my $Categories;
  if ($in{'input'}->{'RECORD'}->{'CATEGORIES'} eq "*") {
    $Categories = "All";
  } elsif ($in{'input'}->{'RECORD'}->{'CATEGORIES'}) {
    foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
      $Categories .= $category->{'NAME'}."<br>";
    }
  }
  
  $Body .= $Dialog->TextBox(
    value     => $Categories,
    subject   => "Categories"
  );

  $in{'input'}->{'RECORD'}->{'SIGNATURE'} =~ s/\n/\<br\>/g;
  $Body .= $Dialog->TextArea(
    value     => $in{'input'}->{'RECORD'}->{'SIGNATURE'},
    subject   => "Signature"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a staff account").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;