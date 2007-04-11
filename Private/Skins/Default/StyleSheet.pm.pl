###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/StyleSheet.pm.pl -> StyleSheet skin module                            #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package StyleSheet;

use strict;

sub new {
  my ($class) = @_;

  my $self = {
    "BODY_PADD"             => "5px",
    "BODY_IMAGE"            => "",
    "BODY_BGCOLOR"          => "#FFFFFF",

    "FONT_COLOR"            => "#333333",
    "FONT_FACE"             => "Verdana, sans-serif",
    "FONT_SIZE"             => "2",
    "FONT_SUB_SIZE"         => "1",

    "LINK_COLOR"            => "#3366CC",
    "LINK_VISITED"          => "#3366CC",
    "LINK_HOVER"            => "#3366CC",
    "LINK_ACTIVE"           => "#3366CC",

    "TABLE_BORDER_COLOR"    => "#333333",
    "TABLE_WIDTH"           => "100%",
    "TABLE_PADD"            => "3",
    "TABLE_SPAC"            => "1",

    "TITLE_BGCOLOR"         => "#DDDDDD",
    "TITLE_COLOR"           => "#333333",
    "TITLE_SIZE"            => "2",
    "TITLE_SUB_SIZE"        => "1",

    "MENU_BGCOLOR"          => "#CCCCCC",
    "MENU_COLOR"            => "#333333",
    "MENU_SIZE"             => "1",

    "LARGE_BGCOLOR"         => "#CCCCCC",
    "LARGE_COLOR"           => "#333333",
    "LARGE_SIZE"            => "2",

    "SMALL_BGCOLOR"         => "#333333",
    "SMALL_COLOR"           => "#EEEEEE",
    "SMALL_SIZE"            => "1",

    "ROW_BGCOLOR"           => "#EEEEEE",
    "ROW_COLOR"             => "#333333",
    "ROW_SIZE"              => "2",

    "TBODY_BGCOLOR"         => "#EEEEEE",
    "TBODY_COLOR"           => "#333333",
    "TBODY_SIZE"            => "2",
    "TBODY_SUB_SIZE"        => "1",
    "TBODY_ERROR_COLOR"     => "Red",

    "SUBJECT_COLOR"         => "#333333",
    "SUBJECT_SIZE"          => "2",
    "SUBJECT_SUB_SIZE"      => "1",
    "HELP_COLOR"            => "#333333",
    "HELP_SIZE"             => "2",
    "LABEL_COLOR"           => "#333333",
    "LABEL_SIZE"            => "2",
    "FIELD_COLOR"           => "#333333",
    "FIELD_SIZE"            => "2",

    "FORM_FONT"             => "Verdana, sans-serif",
    "FORM_COLOR"            => "#333333",
    "FORM_BGCOLOR"          => "#FFFFFF",
    "FORM_SIZE"             => "2",
    "FORM_WIDTH"            => "100%"
  };

  return bless ($self, $class);
}

sub DESTROY { }

1;