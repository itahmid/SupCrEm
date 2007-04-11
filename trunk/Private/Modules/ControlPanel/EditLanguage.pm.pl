###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/EditLanguage.pm.pl -> EditLanguage module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::EditLanguage;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/EditLanguage.pm.pl";

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

  my $Skin = Skin::CP::EditLanguage->new();

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

  my @LanguageFiles;
  
  opendir(DIR, "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language") || &Error::CGIError("Error opening directory. $!", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language");
  foreach my $file (grep(/\.lang$/, readdir(DIR))) {
    $file =~ s/\.lang$//;
    push(@LanguageFiles, $file);
  }
  closedir(DIR);

  if (-d "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/ControlPanel") {
    opendir(DIR, "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/ControlPanel") || &Error::CGIError("Error opening directory. $!", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/ControlPanel");
    foreach my $file (grep(/\.lang$/, readdir(DIR))) {
      $file =~ s/\.lang$//;
      push(@LanguageFiles, "CP::".$file);
    }
    closedir(DIR);
  }
      
  
  my %INPUT;
  
  $INPUT{'LANGUAGE_FILES'} = \@LanguageFiles;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditLanguage->new();

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
    !$SD::QUERY{'LANGUAGE'} ||
    !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}")
  ) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  if ($SD::QUERY{'LANGUAGE'} =~ /^CP\:\:(.*)$/) {
    if (!(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/ControlPanel/$1.lang")) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
  } else {
    if (!(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/$SD::QUERY{'LANGUAGE'}.lang")) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
  }    

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my $LANGUAGE = &Standard::GetLanguage($SD::QUERY{'LANGUAGE'});

  my %INPUT;
  
  $INPUT{'LANGUAGE'} = $LANGUAGE;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditLanguage->new();

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
    !$SD::QUERY{'LANGUAGE'} ||
    !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}")
  ) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  
  if ($SD::QUERY{'LANGUAGE'} =~ /^CP\:\:(.*)$/) {
    if (!(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/ControlPanel/$1.lang")) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
  } else {
    if (!(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/$SD::QUERY{'LANGUAGE'}.lang")) {
      $self->show(DB => $in{'DB'});
      return 1;
    }
  }    

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  my $LANGUAGE = &Standard::GetLanguage($SD::QUERY{'LANGUAGE'});
  
  my $NewFile = <<TEXT;
###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg\@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
TEXT

  if ($SD::QUERY{'LANGUAGE'} =~ /^CP\:\:(.*)$/) {
    my $space = " " x (23 - (length($1) * 2));
    $NewFile .= qq~# Skins/Language/ControlPanel/$1.lang -> $1 language module$space#\n~;
  } else {
    my $space = " " x (36 - (length($SD::QUERY{'LANGUAGE'}) * 2));
    $NewFile .= qq~# Skins/Language/$SD::QUERY{'LANGUAGE'}.lang -> $SD::QUERY{'LANGUAGE'} language module$space#\n~;
  }

  $NewFile .= <<TEXT;
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Language::$SD::QUERY{'LANGUAGE'};

require Exporter;

\@ISA       = qw(Exporter);
\@EXPORT    = qw(\@EXPORT_OK);
\@EXPORT_OK = qw(\$LANGUAGE);

use strict;
use vars qw(\$LANGUAGE);

\$LANGUAGE = {
TEXT

  my @Keys = keys(%{ $LANGUAGE });
  for (my $h = 0; $h <= $#Keys; $h++) {
    if (ref($LANGUAGE->{$Keys[$h]}) eq "HASH") {
      my %hash = %{ $LANGUAGE->{$Keys[$h]} };
      my @keys = keys(%hash);

      $NewFile .= "  \"".$Keys[$h]."\"  => {\n";
      for (my $i = 0; $i <= $#keys; $i++) {
        my $value = $SD::QUERY{'FORM_'.$Keys[$h]."-".$keys[$i]};
        $NewFile .= "    \"".$keys[$i]."\"  => qq~".$value."~";
        $NewFile .= "," unless ($i == $#keys);
        $NewFile .= "\n";
      }
      $NewFile .= "  }";
      $NewFile .= "," unless ($h == $#Keys);
      $NewFile .= "\n";
    } else {
      my $value = $SD::QUERY{'FORM_'.$Keys[$h]};
      $NewFile .= "  \"".$Keys[$h]."\"  => qq~".$value."~";
      $NewFile .= "," unless ($h == $#Keys);
      $NewFile .= "\n";
    }
  }

  $NewFile .= <<TEXT;
};

1;
TEXT

  if ($SD::QUERY{'LANGUAGE'} =~ /^CP\:\:(.*)$/) {
    &Standard::FileOpen(*LANG, "w", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/ControlPanel/$SD::QUERY{'LANGUAGE'}.lang");
  } else {
    &Standard::FileOpen(*LANG, "w", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/Language/$SD::QUERY{'LANGUAGE'}.lang");
  }
  
  print LANG $NewFile;
  close(LANG);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::EditLanguage->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do();
  
  return 1;

}

1;