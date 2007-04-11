###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/StyleOptions.pm.pl -> StyleOptions skin module           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::StyleOptions;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use HTML::Dialog;
use HTML::Form;
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
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body = $Dialog->SmallHeader(
    titles => [
      { text => "", width => 1 },
      { text => "description", width => "100%" },
      { text => "id", width => 250, nowrap => 1 }
    ]
  );
  
  $Body .= $Dialog->LargeHeader(title => "Style Options", colspan => 3);
  
  foreach my $skin (@{ $in{'input'}->{'SKINS'} }) {
    my @fields;
    $fields[0] = $Form->Radio(
      radios  => [
        { name => "SKIN", value => $skin->{'ID'} }
      ]
    );
    $fields[1] = $skin->{'DESCRIPTION'};
    $fields[2] = $skin->{'ID'};
    $Body .= $Dialog->Row(fields => \@fields);
  }
  
  my $value = $Form->Button(
    buttons => [
      { type => "submit", value => "Next >" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );
  
  $Body .= $Dialog->Row(fields => $value, colspan => 3);
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "CP", value => "1" },
      { name => "action", value => "ViewStyleOptions" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (input => undef, error => "", @_);

  my @Sections = (
    { title => "Body Properties", items => [
      { subject => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:", type => "text" },
      { name => "BODY_PADD", subject => "Padding", type => "textbox", required => 1 },
      { name => "BODY_IMAGE", subject => "Background Image", type => "textbox" },
      { name => "BODY_BGCOLOR", subject => "Background Color", type => "color", required => 1 }
    ]},
    { title => "Font Properties", items => [
      { name => "FONT_COLOR", subject => "Color", type => "color", required => 1 },
      { name => "FONT_FACE", subject => "Face", type => "textbox", required => 1 },
      { name => "FONT_SIZE", subject => "Size", type => "size", required => 1 },
      { name => "FONT_SUB_SIZE", subject => "Small Size", type => "size", required => 1 }
    ]},
    { title => "Link Properties", items => [
      { name => "LINK_COLOR", subject => "Color", type => "color", required => 1 },
      { name => "LINK_VISITED", subject => "Visited Color", type => "color", required => 1 },
      { name => "LINK_HOVER", subject => "Hover Color", type => "color", required => 1 },
      { name => "LINK_ACTIVE", subject => "Active Color", type => "color", required => 1 }
    ]},
    { title => "Table Properties", items => [
      { name => "TABLE_BORDER_COLOR", subject => "Border Color", type => "color", required => 1 },
      { name => "TABLE_WIDTH", subject => "Width", type => "textbox", required => 1 },
      { name => "TABLE_PADD", subject => "Padding", type => "textbox", required => 1 },
      { name => "TABLE_SPAC", subject => "Spacing", type => "textbox", required => 1 }
    ]},
    { title => "Title Properties", items => [
      { name => "TITLE_BGCOLOR", subject => "Background Color", type => "color", required => 1 },
      { name => "TITLE_COLOR", subject => "Font Color", type => "color", required => 1 },
      { name => "TITLE_SIZE", subject => "Font Size", type => "size", required => 1 },
      { name => "TITLE_SUB_SIZE", subject => "Font Small Size", type => "size", required => 1 }
    ]},
    { title => "Menu Properties", items => [
      { name => "MENU_BGCOLOR", subject => "Background Color", type => "color", required => 1 },
      { name => "MENU_COLOR", subject => "Font Color", type => "color", required => 1 },
      { name => "MENU_SIZE", subject => "Font Size", type => "size", required => 1 }
    ]},
    { title => "Large Header Properties", items => [
      { name => "LARGE_BGCOLOR", subject => "Background Color", type => "color", required => 1 },
      { name => "LARGE_COLOR", subject => "Font Color", type => "color", required => 1 },
      { name => "LARGE_SIZE", subject => "Font Size", type => "size", required => 1 }
    ]},
    { title => "Small Header Properties", items => [
      { name => "SMALL_BGCOLOR", subject => "Background Color", type => "color", required => 1 },
      { name => "SMALL_COLOR", subject => "Font Color", type => "color", required => 1 },
      { name => "SMALL_SIZE", subject => "Font Size", type => "size", required => 1 }
    ]},
    { title => "Row Properties", items => [
      { name => "ROW_BGCOLOR", subject => "Background Color", type => "color", required => 1 },
      { name => "ROW_COLOR", subject => "Font Color", type => "color", required => 1 },
      { name => "ROW_SIZE", subject => "Font Size", type => "size", required => 1 }
    ]},
    { title => "Table Body Properties", items => [
      { name => "TBODY_BGCOLOR", subject => "Background Color", type => "color", required => 1 },
      { name => "TBODY_COLOR", subject => "Font Color", type => "color", required => 1 },
      { name => "TBODY_SIZE", subject => "Font Size", type => "size", required => 1 },
      { name => "TBODY_SUB_SIZE", subject => "Font Small Size", type => "size", required => 1 },
      { name => "TBODY_ERROR_COLOR", subject => "Font Error Color", type => "color", required => 1 }
    ]},
    { title => "Form Properties", items => [
      { name => "SUBJECT_COLOR", subject => "Field Subject Font Color", type => "color", required => 1 },
      { name => "SUBJECT_SIZE", subject => "Field Subject Font Size", type => "size", required => 1 },
      { name => "SUBJECT_SUB_SIZE", subject => "Field Subject Font Small Size", type => "size", required => 1 },
      { name => "HELP_COLOR", subject => "Field Help Font Color", type => "color", required => 1 },
      { name => "HELP_SIZE", subject => "Field Help Font Size", type => "size", required => 1 },
      { name => "LABEL_COLOR", subject => "Field Label Font Color", type => "color", required => 1 },
      { name => "LABEL_SIZE", subject => "Field Label Font Size", type => "size", required => 1 },
      { name => "FIELD_COLOR", subject => "Text Field Value Font Color", type => "color", required => 1 },
      { name => "FIELD_SIZE", subject => "Text Field Value Font Size", type => "size", required => 1 },
      { name => "FORM_BGCOLOR", subject => "Form Element Background Color", type => "color", required => 1 },
      { name => "FORM_FONT", subject => "Form Element Font Face", type => "textbox", required => 1 },
      { name => "FORM_COLOR", subject => "Form Element Font Color", type => "color", required => 1 },
      { name => "FORM_SIZE", subject => "Form Element Font Size", type => "size", required => 1 },
      { name => "FORM_WIDTH", subject => "Form Element Width", type => "textbox", required => 1 },
      { type => "buttons" }
    ]}
  );

  my $LANGUAGE = {
    "MISSING" => { },
    "ERROR"   => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };
  
  foreach my $section (@Sections) {
    foreach my $item (@{ $section->{'items'} }) {
      $LANGUAGE->{'MISSING'}->{ $item->{'name'} } = qq~<li>You didn't fill in the "$item->{'subject'}" field.~ if ($item->{'subject'});
    }
  }
  
  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});
  $Sections[0]->{'items'}->[0]->{'subject'} .= $in{'error'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Script = <<HTML;
<script language="JavaScript">
  <!--
  function openColourPicker(cell,form,field) {
    var thewindow = window.open("", "newwindow", "width=295,height=50");

    c = new Array();
    c[1] = "FF";
    c[2] = "CC";
    c[3] = "99";
    c[4] = "66";
    c[5] = "33";
    c[6] = "00";

    thewindow.document.write("<html>\\n<head>\\n<title>Color Picker</title>\\n</head>\\n<body marginheight=\\"2\\" marginwidth=\\"2\\" topmargin=\\"2\\" leftmargin=\\"2\\">\\n");

    thewindow.document.write("<script language=\\"JavaScript\\">\\n");
    thewindow.document.write("  function returnColour(colour) {\\n");
    thewindow.document.write("    window.opener.document.all." + cell + ".style.background = colour;\\n");
    thewindow.document.write("    window.opener.document." + form + "." + field + ".value = colour;\\n");
    thewindow.document.write("    window.close();\\n");
    thewindow.document.write("  }\\n");
    thewindow.document.write("  function previewColour(colour) {\\n");
    thewindow.document.write("    document.all.preview.style.background = colour;\\n");
    thewindow.document.write("  }\\n");
    thewindow.document.write("</script>\\n\\n");

    thewindow.document.write("<table cellpadding=\\"0\\" cellspacing=\\"0\\" border=\\"0\\" height=\\"100%\\" width=\\"100%\\">\\n");
    thewindow.document.write("  <tr>\\n");
    thewindow.document.write("    <td>\\n");
    thewindow.document.write("      <table cellpadding=\\"0\\" cellspacing=\\"1\\" border=\\"0\\" bgcolor=\\"#000000\\">\\n");
    thewindow.document.write("        <tr>\\n");

    for (h = 1; h <= 6; h++) {
      if (h > 1) {
        thewindow.document.write("        </tr>\\n");
        thewindow.document.write("        <tr>\\n");
      }
      for (i = 1; i <= 6; i++) {
        for (j = 1; j <= 6; j++) {
          colour = c[h] + c[i] + c[j];
          thewindow.document.write("          <td bgcolor=\\"#" + colour + "\\" width=\\"7\\"><a href=\\"#\\" onClick=\\"returnColour('#" + colour + "')\\" onMouseOver=\\"previewColour('#" + colour + "')\\"><img src=\\"http://www.obsidian-scripts.com/images/offsite/pixel.gif\\" width=\\"7\\" height=\\"7\\" border=\\"0\\"></td>\\n");
        }
      }
    }

    thewindow.document.write("      </table>\\n");
    thewindow.document.write("    </td>\\n");
    thewindow.document.write("  </tr>\\n");
    thewindow.document.write("  <tr>\\n");
    thewindow.document.write("    <td><img src=\\"http://www.obsidian-scripts.com/images/offsite/pixel.gif\\" height=\\"10\\" border=\\"0\\"></td>\\n");
    thewindow.document.write("  </tr>\\n");
    thewindow.document.write("  <tr>\\n");
    thewindow.document.write("    <td height=\\"100%\\">\\n");
    thewindow.document.write("      <table cellpadding=\\"0\\" cellspacing=\\"1\\" border=\\"0\\" bgcolor=\\"#000000\\" width=\\"100%\\" height=\\"100%\\">\\n");
    thewindow.document.write("        <tr>\\n");
    thewindow.document.write("          <td id=\\"preview\\" bgcolor=\\"#FFFFFF\\" height=\\"100%\\"><img src=\\"http://www.obsidian-scripts.com/images/offsite/pixel.gif\\" height=\\"100%\\" border=\\"0\\"></td>\\n");
    thewindow.document.write("        </tr>\\n");
    thewindow.document.write("      </table>\\n");
    thewindow.document.write("    </td>\\n");
    thewindow.document.write("  </tr>\\n");
    thewindow.document.write("</table>\\n\\n");
    thewindow.document.write("</body>\\n</html>\\n");
  }
  //-->
</script>
HTML

  my $Body = $Dialog->SmallHeader(titles => "style options");
  
  foreach my $section (@Sections) {
    $Body .= $Dialog->LargeHeader(title => $section->{'title'}) if ($section->{'title'});

    my $Temp;
    foreach my $item (@{ $section->{'items'} }) {
      if ($item->{'type'} eq "textbox") {
        $Temp .= $Dialog->TextBox(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $in{'input'}->{'STYLE'}->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'}
        );
      } elsif ($item->{'type'} eq "color") {
        my $value = qq~<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>~;
        $value .= $Form->TextBox(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $in{'input'}->{'STYLE'}->{$item->{'name'}},
          extra     => "onBlur=\"document.all.CELL_$item->{'name'}.style.background=document.form.FORM_$item->{'name'}.value\""
        );
        $value .= qq~</td><td width="25"><table cellpadding="0" cellspacing="1" border="0" bgcolor="#333333" width="100%"><tr>~;
        $value .= qq~<td id="CELL_$item->{'name'}" bgcolor="~.($SD::QUERY{'FORM_'.$item->{'name'}} || $in{'input'}->{'STYLE'}->{$item->{'name'}}).qq~"><a href="#" onClick="openColourPicker('CELL_$item->{'name'}', 'form', 'FORM_$item->{'name'}')"><img src="http://www.obsidian-scripts.com/images/offsite/pixel.gif" width="25" height="20" border="0" alt="Color Picker"></a></td></tr></table>~;
        $value .= qq~</td></tr></table>~;
        $Temp .= $Dialog->TextBox(
          value     => $value,
          subject   => $item->{'subject'},
          required  => $item->{'required'}
        );
      } elsif ($item->{'type'} eq "size") {
        $Temp .= $Dialog->Radio(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $in{'input'}->{'STYLE'}->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          radios    => [
            { value => "1", label => "1" },
            { value => "2", label => "2" },
            { value => "3", label => "3" },
            { value => "4", label => "4" }
          ], join => "&nbsp;"
        );
      } elsif ($item->{'type'} eq "text") {
        $Temp .= $Dialog->Text(text => $item->{'subject'});
      } elsif ($item->{'type'} eq "buttons") {
        $Temp .= $Dialog->Button(
          buttons   => [
            { type => "submit", value => "Modify" },
            { type => "reset", value => "Cancel" }
          ], join => "&nbsp;"
        );
      }
    }
    $Body .= $Dialog->Dialog(body => $Temp);
  }
  
  $Body = $Dialog->Body($Body);
  $Body = $Script.$Body;
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "SKIN", value => $SD::QUERY{'SKIN'} },
      { name => "action", value => "DoStyleOptions" },
      { name => "CP", value => "1" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ]
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The style options have been updated.");
     $Body = $Dialog->Dialog(body => $Body);
  
     $Body = $Dialog->SmallHeader(titles => "style options").$Body;
     
     $Body = $Dialog->Body($Body);
     $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;