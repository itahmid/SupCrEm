###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/EditTemplate.pm.pl -> EditTemplate skin module           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::EditTemplate;

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
      { text => "description", width => "100%" },
      { text => "id", width => 250, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Edit Template", colspan => 3);
  
  foreach my $skin (@{ $in{'input'}->{'SKINS'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "SKIN", value => $skin->{'ID'} }
      ]
    );
    $fields[1] = $skin->{'DESCRIPTION'};
    $fields[2] = $skin->{'ID'};
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
      { name => "action", value => "ListEditTemplate" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# list subroutine
sub list {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body = $Dialog->SmallHeader(
    titles => [
      { text => "", width => 1 },
      { text => "template", width => "100%" }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Edit Template", colspan => 2);
  
  foreach my $file (@{ $in{'input'}->{'TEMPLATES'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "TEMPLATE", value => $file }
      ]
    );
    $fields[1] = $file;
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 2);
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "SKIN", value => $SD::QUERY{'SKIN'} },
      { name => "CP", value => "1" },
      { name => "action", value => "ViewEditTemplate" },
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

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body = $Dialog->Text(text => "<b>$SD::QUERY{'TEMPLATE'}</b>");

  my $value = $Form->TextArea(
    name      => "FORM_CONTENT",
    value     => &Standard::HTMLize($SD::QUERY{'FORM_CONTENT'} || $in{'input'}->{'CONTENT'}),
    rows      => 20
  );
  $Body .= $Dialog->Text(text => $value);

  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Modify" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "edit template").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "SKIN", value => $SD::QUERY{'SKIN'} },
      { name => "TEMPLATE", value => $SD::QUERY{'TEMPLATE'} },
      { name => "action", value => "DoEditTemplate" },
      { name => "CP", value => "1" },
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

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The template has been updated.");
     $Body = $Dialog->Dialog(body => $Body);
  
     $Body = $Dialog->SmallHeader(titles => "edit template").$Body;
     
     $Body = $Dialog->Body($Body);
     $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;