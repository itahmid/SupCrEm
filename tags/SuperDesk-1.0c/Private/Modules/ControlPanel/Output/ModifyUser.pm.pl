###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/ModifyUser.pm.pl -> ModifyUser skin module               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::ModifyUser;

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
  
  $Body .= $Dialog->LargeHeader(title => "Modify a User", colspan => 3);
  
  foreach my $user (@{ $in{'input'}->{'USER_ACCOUNTS'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "USERNAME", value => $user->{'USERNAME'} }
      ]
    );
    
    $fields[1]  = qq~<a href="$SYSTEM->{'SCRIPT_URL'}?CP=1&action=UserProfile&USERNAME=$user->{'USERNAME'}&Username=$SD::ADMIN{'USERNAME'}&Password=$SD::ADMIN{'PASSWORD'}">~;
    $fields[1] .= $user->{'NAME'};
    $fields[1] .= qq~</a>~;
    
    $fields[2] = $user->{'USERNAME'};
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
      { name => "action", value => "ViewModifyUser" },
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
      "URL"           => qq~<li>The value for the "Website URL" field must be 256 characters or less.~
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
    value     => $in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'},
    subject   => "Username"
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_PASSWORD",
    value     => $SD::QUERY{'FORM_PASSWORD'} || $in{'input'}->{'USER_ACCOUNT'}->{'PASSWORD'},
    subject   => "Password",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_NAME",
    value     => $SD::QUERY{'FORM_NAME'} || $in{'input'}->{'USER_ACCOUNT'}->{'NAME'},
    subject   => "Name",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_EMAIL",
    value     => $SD::QUERY{'FORM_EMAIL'} || $in{'input'}->{'USER_ACCOUNT'}->{'EMAIL'},
    subject   => "Email",
    required  => 1
  );

  my $subfield  = qq~<table cellpadding="0" cellspacing="0" border="0" width="100%">~;
     $subfield .= qq~<tr><td width="100%">~;
     $subfield .= $Form->TextBox(name => "ITEM_OTHER_EMAILS");
     $subfield .= qq~</td><td width="5" nowrap></td><td width="1" nowrap>~;
     $subfield .= $Form->Button(buttons => [{ type => "button", value => "Add", extra => "onClick=\"OTHER_EMAILS_AddOption(form)\"" }]);
     $subfield .= qq~</td></tr></table>~;

  $Body .= $Dialog->TextArea(
    name      => "FORM_OTHER_EMAILS",
    value     => $SD::QUERY{'FORM_OTHER_EMAILS'} || $in{'input'}->{'USER_ACCOUNT'}->{'OTHER_EMAILS'},
    subject   => "Other Email Addresses",
    rows      => 3,
    "sub-field" => $subfield
  );        

  $Body .= $Dialog->TextBox(
    name      => "FORM_URL",
    value     => $SD::QUERY{'FORM_URL'} || $in{'input'}->{'USER_ACCOUNT'}->{'URL'},
    subject   => "Website URL"
  );

  $Body .= $Dialog->Radio(
    name      => "FORM_STATUS",
    value     => $SD::QUERY{'FORM_STATUS'} || $in{'input'}->{'USER_ACCOUNT'}->{'STATUS'},
    subject   => "Status",
    required  => 1,
    radios    => [
      { value => "30", label => "Inactive" },
      { value => "50", label => "Active" }
    ], join => "&nbsp;"
  );

  my @options;
  foreach my $key (sort keys %{ $GENERAL->{'USER_LEVELS'} }) {
    push(@options, { value => $key, text => $GENERAL->{'USER_LEVELS'}->{$key} });
  }

  $Body .= $Dialog->SelectBox(
    name      => "FORM_LEVEL",
    value     => $SD::QUERY{'FORM_LEVEL'} || $in{'input'}->{'USER_ACCOUNT'}->{'LEVEL'},
    subject   => "Level",
    required  => 1,
    options   => \@options
  );

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Modify" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  my $Script = <<HTML;
<script language="JavaScript">
  <!--
  function OTHER_EMAILS_AddOption(f) {
    var filter = f.FORM_OTHER_EMAILS;
    var item = f.ITEM_OTHER_EMAILS;

    if (item.value != "") {
      if (filter.value != "") {
        filter.value = filter.value + item.value + "|";
      } else {
        filter.value = "|" + item.value + "|";
      }
    }
    item.value = "";
  }
  //-->
</script>
HTML

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a user").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Script.$Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "USERNAME", value => $in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'} },
      { name => "CP", value => "1" },
      { name => "action", value => "DoModifyUser" },
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

  my $Body = $Dialog->Text(text => "The following user has been modified:");

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

  my @emails;
  foreach my $email (split(/\|/, $in{'input'}->{'RECORD'}->{'OTHER_EMAILS'})) {
    push(@emails, $email) if ($email);
  }
  
  $Body .= $Dialog->TextBox(
    value     => join("<br>", @emails),
    subject   => "Other Email Addresses"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'URL'},
    subject   => "Website URL"
  );

  $Body .= $Dialog->TextBox(
    value     => ($in{'input'}->{'RECORD'}->{'STATUS'} == 50 ? "Active" : "Inactive"),
    subject   => "Status"
  );

  $Body .= $Dialog->TextBox(
    value     => $GENERAL->{'USER_LEVELS'}->{ $in{'input'}->{'RECORD'}->{'LEVEL'} },
    subject   => "Level"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a user").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;