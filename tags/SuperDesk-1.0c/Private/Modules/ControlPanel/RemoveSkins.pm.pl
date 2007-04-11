###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/RemoveSkins.pm.pl -> RemoveSkins module                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::RemoveSkins;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use strict;

require "ControlPanel/Output/RemoveSkins.pm.pl";

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
  # Getting data...                                                      #

  my @Skins;
  
  opendir(DIR, "$SD::PATH/Private/Skins") || &Error::CGIError("Error opening directory for reading. $!", "$SD::PATH/Private/Skins");
  foreach my $file (grep(/\.cfg$/, readdir(DIR))) {
    my $id = $file;
       $id =~ s/\.cfg$//;
    
    &Standard::FileOpen(*CFG, "r", "$SD::PATH/Private/Skins/$file");
    push(@Skins, { ID => $id, DESCRIPTION => join("", <CFG>) }) unless ($id eq "Default");
    close(CFG);
  }
  closedir(DIR);

  my %INPUT;
  
  $INPUT{'SKINS'} = \@Skins;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveSkins->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

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

  my @SKIN = $SD::CGI->param('SKIN');
  
  if (scalar(@SKIN) < 1) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Deleting data...                                                     #

  foreach my $id (@SKIN) {
    unless ($id eq "Default") {
      rmtree("$SD::PATH/Private/Skins/$id") || &Error::CGIError("Error removing \"$id\" skin directory. $!", "$SD::PATH/Private/Skins/$id");
      unlink("$SD::PATH/Private/Skins/$id.cfg") || &Error::CGIError("Error removing \"$id\" skin description file. $!", "$SD::PATH/Private/Skins/$id.cfg");
      if ($id eq $SD::GLOBAL{'SKIN'}) {
        $SD::GLOBAL{'SKIN'} = "Default";
      }
      if ($id eq $GENERAL->{'SKIN'}) {
        require "Variables.pm.pl";
        my $Variables = Variables->new();
        $Variables->Update(
          FILE      => "$SD::PATH/Private/Variables/General.pm.pl",
          PACKAGE   => "General",
          VARIABLE  => "GENERAL",
          VALUES    => {
            SKIN  => "Default"
          }
        ) || &Error::CGIError("Error updating configuration file. $Variables->{'ERROR'}", "$SD::PATH/Private/Variables/General.pm.pl");
      }
    }
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::RemoveSkins->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do();
  
  return 1;
}

1;