###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/CreateSkin.pm.pl -> CreateSkin skin module               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::CreateSkin;

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
      "ID"            => qq~<li>You didn't fill in the "ID" field.~,
      "DESCRIPTION"   => qq~<li>You didn't fill in the "Description" field.~
    },
    "ALREADYEXISTS" => {
      "ID"            => qq~<li>The value you entered for the "ID" field already exists.~
    },
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form   = HTML::Form->new();

  my $Body = $Dialog->Text(text => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:".$in{'error'});

  $Body .= $Dialog->TextBox(
    name      => "FORM_ID",
    value     => $SD::QUERY{'FORM_ID'},
    subject   => "ID",
    required  => 1
  );
  
  $Body .= $Dialog->TextBox(
    name      => "FORM_DESCRIPTION",
    value     => $SD::QUERY{'FORM_DESCRIPTION'},
    subject   => "Description",
    required  => 1
  );

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Add" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "create a skin").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "DoCreateSkin" },
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

  my $Body = $Dialog->Text(text => "The following skin has been created:");

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'ID'},
    subject   => "ID"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'RECORD'}->{'DESCRIPTION'},
    subject   => "Description"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "create a skin").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;