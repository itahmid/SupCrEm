###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveBackup.pm.pl -> RemoveBackup module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveBackup;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use strict;

require "ControlPanel/Output/RemoveBackup.pm.pl";

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# do subroutine
sub do {
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
  # Removing data...                                                     #

  if (-e "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.tar.gz") {
    unlink("$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.tar.gz") || &Error::CGIError("Error removing backup package. $!", "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.tar.gz");
  } elsif (-e "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.tar") {
    unlink("$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.tar") || &Error::CGIError("Error removing backup package. $!", "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.tar");
  }
  
  if (-d "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}") {
    rmtree("$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}") || &Error::CGIError("Error removing backup directory. $!", "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}");
  }
  
  unlink("$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.log") || &Error::CGIError("Error removing backup log file. $!", "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.log");
  if (-e "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.txt") {
    unlink("$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.txt") || &Error::CGIError("Error removing backup description file. $!", "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'BACKUP'}.txt");
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveBackup->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do();
  
  return 1;
}

1;