###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/ModifyCategory.pm.pl -> ModifyCategory skin module       #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::ModifyCategory;

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
      { text => "id", width => 1, nowrap => 1 },
      { text => "name", width => "100%" },
      { text => "contact", width => 250, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Modify a Category", colspan => 4);
  
  foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "CID", value => $category->{'ID'} }
      ]
    );
    $fields[1] = $category->{'ID'};
    $fields[2] = $category->{'NAME'};
    $fields[3] = qq~<a href="mailto:$category->{'CONTACT_EMAIL'}">$category->{'CONTACT_NAME'}</a>~;
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 4);
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "ViewModifyCategory" },
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
      "NAME"          => qq~<li>You didn't fill in the "Name" field.~,
      "CONTACT_NAME"  => qq~<li>You didn't fill in the "Contact Name" field.~,
      "CONTACT_EMAIL" => qq~<li>You didn't fill in the "Contact Email" field.~
    },
    "TOOLONG" => {
      "NAME"          => qq~<li>The value for the "Name" field must be 128 characters or less.~,
      "DESCRIPTION"   => qq~<li>The value for the "Description" field must be 512 characters or less.~,
      "CONTACT_NAME"  => qq~<li>The value for the "Contact Name" field must be 128 characters or less.~,
      "CONTACT_EMAIL" => qq~<li>The value for the "Contact Email" field must be 128 characters or less.~
    },
    "ERROR"   => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:".$in{'error'});

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'CATEGORY'}->{'ID'},
    subject   => "ID"
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_NAME",
    value     => $SD::QUERY{'FORM_NAME'} || $in{'input'}->{'CATEGORY'}->{'NAME'},
    subject   => "Name",
    required  => 1
  );
  
  $Body .= $Dialog->TextArea(
    name      => "FORM_DESCRIPTION",
    value     => $SD::QUERY{'FORM_DESCRIPTION'} || $in{'input'}->{'CATEGORY'}->{'DESCRIPTION'},
    subject   => "Description",
    rows      => 3
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_CONTACT_NAME",
    value     => $SD::QUERY{'FORM_CONTACT_NAME'} || $in{'input'}->{'CATEGORY'}->{'CONTACT_NAME'},
    subject   => "Contact Name",
    required  => 1
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_CONTACT_EMAIL",
    value     => $SD::QUERY{'FORM_CONTACT_EMAIL'} || $in{'input'}->{'CATEGORY'}->{'CONTACT_EMAIL'},
    subject   => "Contact Email",
    required  => 1
  );

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Modify" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a category").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CID", value => $in{'input'}->{'CATEGORY'}->{'ID'} },
      { name => "CP", value => "1" },
      { name => "action", value => "DoModifyCategory" },
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

  my $Body = $Dialog->Text(text => "The following category has been modified:");

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'CATEGORY'}->{'ID'},
    subject   => "ID"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'NAME'},
    subject   => "Name"
  );
  
  $Body .= $Dialog->TextArea(
    value     => $in{'input'}->{'RECORD'}->{'DESCRIPTION'},
    subject   => "Description"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'CONTACT_NAME'},
    subject   => "Contact Name"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'CONTACT_EMAIL'},
    subject   => "Contact Email"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a category").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;