###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/Login.pm.pl -> Login module                                    #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::Login;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/Login.pm.pl";

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# show subroutine
sub show {
  my $self = shift;
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::Login->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);
  
  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  if ($SD::QUERY{'FORM_STORE_DETAILS'}) {
    $SD::COOKIES{'CP-Username'} = $SD::ADMIN{'USERNAME'};
    $SD::COOKIES{'CP-Password'} = $SD::ADMIN{'PASSWORD'};
  }
  
  my $Action = $SD::QUERY{'REFERER'} || "Index";
  my $Page   = $SD::ACTIONS{'CP'}->{$Action};

  if (ref($Page) eq "CODE") {
    eval &$Page;
    if ($@) {
      &Error::CGIError("Error evaluating code reference. $@", "");
    } else {
      return 1;
    }
  } elsif ($Page) {
    require "ControlPanel/$Page->[0].pm.pl";
    my $Source = eval("CP::".$Page->[0]."->new()");
    eval("\$Source->".$Page->[1]."(DB => \$in{'DB'})");
    if ($@) {
      &Error::CGIError("Error evaluating the \"$Page->[1]\" subroutine in the \"CP::$Page->[0]\" package. $@", "");
    } else {
      return 1;
    }
  } else {
    &Error::CGIError("Could not find action \"$Action\"", "");
  }
}

1;