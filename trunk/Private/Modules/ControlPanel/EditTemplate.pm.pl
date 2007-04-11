###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/EditTemplate.pm.pl -> EditTemplate module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::EditTemplate;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/EditTemplate.pm.pl";

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
    push(@Skins, { ID => $id, DESCRIPTION => join("", <CFG>) });
    close(CFG);
  }
  closedir(DIR);

  my %INPUT;
  
  $INPUT{'SKINS'} = \@Skins;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditTemplate->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

###############################################################################
# list subroutine
sub list {
  my $self = shift;
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (!$SD::QUERY{'SKIN'} || !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}")) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my @Templates;
  
  opendir(DIR, "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates") || &Error::CGIError("Error opening directory. $!", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates");
  foreach my $file (readdir(DIR)) {
    if (-d "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$file" && $file !~ /^\.\.?$/) {
      opendir(SUBDIR, "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$file") || &Error::CGIError("Error opening directory. $!", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$file");
      foreach my $subfile (readdir(SUBDIR)) {
        if ($subfile =~ /\.htm$/ || $subfile =~ /\.txt$/) {
          push(@Templates, "$file/$subfile");
        }
      }
      closedir(SUBDIR);
    } elsif ($file =~ /\.htm$/ || $file =~ /\.txt$/) {
      push(@Templates, $file);
    }
  }
  closedir(DIR);
  
  my %INPUT;
  
  $INPUT{'TEMPLATES'} = \@Templates;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditTemplate->new();

  &Standard::PrintHTMLHeader();
  print $Skin->list(input => \%INPUT);
  
  return 1;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (DB => undef, ERROR => "", @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  if (
    !$SD::QUERY{'SKIN'}     ||
    !$SD::QUERY{'TEMPLATE'} ||
    !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}") ||
    !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$SD::QUERY{'TEMPLATE'}")
  ) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  &Standard::FileOpen(*TEMPLATE, "r", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$SD::QUERY{'TEMPLATE'}");
  my $Content = join("", <TEMPLATE>);
  close(TEMPLATE);

  my %INPUT;
  
  $INPUT{'CONTENT'} = $Content;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditTemplate->new();

  &Standard::PrintHTMLHeader();
  print $Skin->view(input => \%INPUT);
  
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

  if (
    !$SD::QUERY{'SKIN'}     ||
    !$SD::QUERY{'TEMPLATE'} ||
    !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}") ||
    !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$SD::QUERY{'TEMPLATE'}")
  ) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my %RECORD;
  
  $RECORD{'CONTENT'} = $SD::QUERY{'FORM_CONTENT'};

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  &Standard::FileOpen(*TEMPLATE, "w", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Templates/$SD::QUERY{'TEMPLATE'}");
  print TEMPLATE $RECORD{'CONTENT'};
  close(TEMPLATE);

  my %INPUT;
  
  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditTemplate->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;

}

1;