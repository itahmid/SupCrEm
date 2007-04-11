###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/ViewBackupLog.pm.pl -> ViewBackupLog module                    #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::ViewBackupLog;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/ViewBackupLog.pm.pl";

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
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #
  
  if (!$SD::QUERY{'BACKUP'} || !(-e "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.log")) {
    require "ControlPanel/Restore.pm.pl";
    my $Source = CP::Restore->new();
       $Source->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  &Standard::FileOpen(*LOG, "r", "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.log");
  my $Log = join("", <LOG>);
  close(LOG);

  my %INPUT;
  
  $INPUT{'LOG'} = $Log;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ViewBackupLog->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

1;