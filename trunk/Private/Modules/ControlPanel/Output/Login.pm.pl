###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/Login.pm.pl -> Login skin module                         #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::Login;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use HTML::Dialog;
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
  my %in = (error => undef, @_);

  my $LANGUAGE = {
    "INVALID" => {
      "Username"    => qq~<li>The Username you entered is invalid.~,
      "Password"    => qq~<li>The Password you entered is invalid.~
    },
    "ERROR"         => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  my $Body  = $Dialog->Text(text => "To login to the Control Panel please enter your username and password below:".$in{'error'});
     $Body .= $Dialog->TextBox(
       name     => "Username",
       value    => $SD::QUERY{'Username'},
       subject  => "Username"
     );
     $Body .= $Dialog->TextBox(
       name     => "Password",
       value    => $SD::QUERY{'Password'},
       subject  => "Password",
       password => 1
     );
     $Body .= $Dialog->CheckBox(
       name       => "FORM_STORE_DETAILS",
       value      => $SD::QUERY{'FORM_STORE_DETAILS'},
       checkboxes => [
         { value => "1", label => "Remember your username and password?" }
       ]
     );
     $Body .= $Dialog->Button(
       buttons  => [
         { type => "submit", value => "Login" },
         { type => "reset", value => "Cancel" }
       ], join => "&nbsp;"
     );

  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->LargeHeader(title => "Login").$Body;
  $Body = $Dialog->SmallHeader(titles => "control panel").$Body;
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "DoLogin" },
      { name => "REFERER", value => ($SD::QUERY{'action'} eq "Login" || $SD::QUERY{'action'} eq "DoLogin" || $SD::QUERY{'action'} eq "Logout" ? $SD::QUERY{'REFERER'} : $SD::QUERY{'action'}) }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;