###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/StyleOptions.pm.pl -> StyleOptions module                      #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::StyleOptions;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use strict;

require "ControlPanel/Output/StyleOptions.pm.pl";

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

  my $Skin = Skin::CP::StyleOptions->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
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

  if (!$SD::QUERY{'SKIN'} || !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}")) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  eval { require "Skins/$SD::QUERY{'SKIN'}/StyleSheet.pm.pl" } || ($self->show(DB => $in{'DB'}) and return 1);
  
  my $STYLE = StyleSheet->new();

  my %INPUT;
  
  $INPUT{'STYLE'} = $STYLE;
	
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::StyleOptions->new();

  &Standard::PrintHTMLHeader();
  print $Skin->view(input => \%INPUT, error => $in{'ERROR'});
  
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

  if (!$SD::QUERY{'SKIN'} || !(-e "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}")) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  my @Fields = (
    { name => "BODY_PADD"         , required => 1 },
    { name => "BODY_IMAGE" },
    { name => "BODY_BGCOLOR"      , required => 1 },
    { name => "FONT_COLOR"        , required => 1 },
    { name => "FONT_FACE"         , required => 1 },
    { name => "FONT_SIZE"         , required => 1 },
    { name => "FONT_SUB_SIZE"     , required => 1 },
    { name => "LINK_COLOR"        , required => 1 },
    { name => "LINK_VISITED"      , required => 1 },
    { name => "LINK_HOVER"        , required => 1 },
    { name => "LINK_ACTIVE"       , required => 1 },
    { name => "TABLE_BORDER_COLOR", required => 1 },
    { name => "TABLE_WIDTH"       , required => 1 },
    { name => "TABLE_PADD"        , required => 1 },
    { name => "TABLE_SPAC"        , required => 1 },
    { name => "TITLE_BGCOLOR"     , required => 1 },
    { name => "TITLE_COLOR"       , required => 1 },
    { name => "TITLE_SIZE"        , required => 1 },
    { name => "TITLE_SUB_SIZE"    , required => 1 },
    { name => "MENU_BGCOLOR"      , required => 1 },
    { name => "MENU_COLOR"        , required => 1 },
    { name => "MENU_SIZE"         , required => 1 },
    { name => "LARGE_BGCOLOR"     , required => 1 },
    { name => "LARGE_COLOR"       , required => 1 },
    { name => "LARGE_SIZE"        , required => 1 },
    { name => "SMALL_BGCOLOR"     , required => 1 },
    { name => "SMALL_COLOR"       , required => 1 },
    { name => "SMALL_SIZE"        , required => 1 },
    { name => "ROW_BGCOLOR"       , required => 1 },
    { name => "ROW_COLOR"         , required => 1 },
    { name => "ROW_SIZE"          , required => 1 },
    { name => "TBODY_BGCOLOR"     , required => 1 },
    { name => "TBODY_COLOR"       , required => 1 },
    { name => "TBODY_SIZE"        , required => 1 },
    { name => "TBODY_SUB_SIZE"    , required => 1 },
    { name => "TBODY_ERROR_COLOR" , required => 1 },
    { name => "SUBJECT_COLOR"     , required => 1 },
    { name => "SUBJECT_SIZE"      , required => 1 },
    { name => "SUBJECT_SUB_SIZE"  , required => 1 },
    { name => "HELP_COLOR"        , required => 1 },
    { name => "HELP_SIZE"         , required => 1 },
    { name => "LABEL_COLOR"       , required => 1 },
    { name => "LABEL_SIZE"        , required => 1 },
    { name => "FIELD_COLOR"       , required => 1 },
    { name => "FIELD_SIZE"        , required => 1 },
    { name => "FORM_BGCOLOR"      , required => 1 },
    { name => "FORM_FONT"         , required => 1 },
    { name => "FORM_COLOR"        , required => 1 },
    { name => "FORM_SIZE"         , required => 1 },
    { name => "FORM_WIDTH"        , required => 1 }
  );

  my (%RECORD, @Error);

  foreach my $field (@Fields) {
    if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}} eq "") {
      push(@Error, "MISSING-".$field->{'name'});
    } else {
      $RECORD{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
    }
  }

  if (scalar(@Error) >= 1) {
    $self->view(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  require "Skins/$SD::QUERY{'SKIN'}/StyleSheet.pm.pl";
  
  my $STYLE = StyleSheet->new();

  my $NewFile = <<TEXT;
###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg\@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/StyleSheet.pm.pl -> StyleSheet skin module                            #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package StyleSheet;

use strict;

sub new {
  my (\$class) = \@_;
	
  my \$self = {
TEXT

  my @Keys = keys(%{ $STYLE });
  for (my $h = 0; $h <= $#Keys; $h++) {
    $NewFile .= "    \"".$Keys[$h]."\"  => \"".$RECORD{$Keys[$h]}."\"";
    $NewFile .= "," unless ($h == $#Keys);
    $NewFile .= "\n";
  }

  $NewFile .= <<TEXT;
  };

  return bless (\$self, \$class);
}

sub DESTROY { }

1;
TEXT

  &Standard::FileOpen(*STYLE, "w", "$SD::PATH/Private/Skins/$SD::QUERY{'SKIN'}/StyleSheet.pm.pl");
  print STYLE $NewFile;
  close(STYLE);

  my %INPUT;
  
  $INPUT{'STYLE'} = $STYLE;
  $INPUT{'RECORD'} = \%RECORD;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::StyleOptions->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;

}

1;