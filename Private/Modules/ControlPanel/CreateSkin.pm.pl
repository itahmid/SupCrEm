###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/CreateSkin.pm.pl -> CreateSkin module                          #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::CreateSkin;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Find;
use File::Copy;
use Cwd;
use strict;

require "ControlPanel/Output/CreateSkin.pm.pl";

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
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateSkin->new();

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
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (
    { name => "ID"           , required => 1, size => 20  },
    { name => "DESCRIPTION"  , required => 1, size => 512 }
  );

  my (%RECORD, %INPUT, @Error);

  foreach my $field (@Fields) {
    if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}} eq "") {
      push(@Error, "MISSING-".$field->{'name'});
    } elsif ($field->{'size'} && $SD::QUERY{'FORM_'.$field->{'name'}} ne "" && length($SD::QUERY{'FORM_'.$field->{'name'}}) > $field->{'size'}) {
      push(@Error, "TOOLONG-".$field->{'name'});
    } else {
      $RECORD{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
    }
  }

  if ($RECORD{'ID'} && (-e "$SD::PATH/Private/Skins/$RECORD{'ID'}.cfg" || -e "$SD::PATH/Private/Skins/$RECORD{'ID'}")) {
    push(@Error, "ALREADYEXISTS-ID");
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  mkdir("$SD::PATH/Private/Skins/$RECORD{'ID'}", 0777) || &Error::CGIError("Error creating \"$RECORD{'ID'}\" skin directory. $!", "$SD::PATH/Private/Skins/$RECORD{'ID'}");
  chmod(0777, "$SD::PATH/Private/Skins/$RECORD{'ID'}");
  
  my $Cwd = cwd();
  
  my (@Files, @Directories);
  my $FindSub = eval {
    sub {
      if (-f) {
        push(@Files, $File::Find::name);
      } elsif (-d && $_ !~ /^\.\.?$/) {
        push(@Directories, $File::Find::name);
      }
    }
  };

  chdir("$SD::PATH/Private/Skins/Default");
  find(\&$FindSub, ".");
  
  chdir($Cwd);

  foreach my $directory (sort @Directories) {
    $directory =~ s/^\.\///;
    mkdir("$SD::PATH/Private/Skins/$RECORD{'ID'}/$directory", 0777) || &Error::CGIError("Error creating directory. $!", "$SD::PATH/Private/Skins/$RECORD{'ID'}/$directory");
    chmod(0777, "$SD::PATH/Private/Skins/$RECORD{'ID'}/$directory");
  }
  foreach my $file (@Files) {
    $file =~ s/^\.\///;
    copy("$SD::PATH/Private/Skins/Default/$file", "$SD::PATH/Private/Skins/$RECORD{'ID'}/$file") || &Error::CGIError("Error copying file. $!", "$SD::PATH/Private/Skins/Default/$file");
    chmod(0666, "$SD::PATH/Private/Skins/$RECORD{'ID'}/$file");
  }

  &Standard::FileOpen(*CFG, "w", "$SD::PATH/Private/Skins/$RECORD{'ID'}.cfg");
  print CFG $RECORD{'DESCRIPTION'};
  close(CFG);

  my %INPUT;
  
  $INPUT{'RECORD'} = \%RECORD;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::CreateSkin->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;