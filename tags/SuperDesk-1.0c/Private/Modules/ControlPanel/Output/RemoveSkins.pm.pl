###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/RemoveSkins.pm.pl -> RemoveSkins skin module             #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::RemoveSkins;

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
  
  $Body .= $Dialog->LargeHeader(title => "Remove Skins", colspan => 3);
  
  foreach my $skin (@{ $in{'input'}->{'SKINS'} }) {
    my @fields;
    $fields[0] = $Form->CheckBox(
      checkboxes  => [
        { name => "SKIN", value => $skin->{'ID'} }
      ]
    );
    $fields[1] = $skin->{'DESCRIPTION'};
    $fields[2] = $skin->{'ID'};
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "button", value => "Select All", extra => "onClick=\"checkAll()\"" },
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 3);

  my $Script  = qq~<script language="JavaScript">\n~;
     $Script .= qq~  <!--\n~;
     $Script .= qq~  function checkAll() {\n~;

  if (scalar(@{ $in{'input'}->{'SKINS'} }) == 1) {
    $Script .= qq~    document.form.SKIN.checked = true;\n~;
  } elsif (scalar(@{ $in{'input'}->{'SKINS'} }) > 1) {
    $Script .= qq~    for (var h = 0; h <= ~.(scalar(@{ $in{'input'}->{'SKINS'} }) - 1).qq~; h++) {\n~;
    $Script .= qq~      document.form.SKIN[h].checked = true;\n~;
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
      { name => "action", value => "DoRemoveSkins" },
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

  my $Body = $Dialog->Text(text => "The selected skins have been removed.");

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "remove skins").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;