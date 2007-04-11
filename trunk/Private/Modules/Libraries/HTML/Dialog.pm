###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/HTML/Dialog.pm -> Dialog HTML module                     #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package HTML::Dialog;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }

use HTML::Form;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# Page subroutine
sub Page {
  my $self = shift;
  my %in = (
    "title"       => "SuperDesk Control Panel",
    "metas"       => [ # name, http-equiv, content
      { name => "GENERATOR", content => "SuperDesk $SD::VERSION, www.plasmapulse.com" }
    ],
    "head-extra"  => "<link type=\"text/css\" href=\"$SYSTEM->{'SCRIPT_URL'}?action=StyleSheet\" rel=\"stylesheet\">",
    "body-class"  => "",
    "body-style"  => "padding-left: 3px; padding-top: 3px; padding-bottom: 3px; padding-right: 3px; margin: 3px",
    "body-extra"  => "marginwidth=\"5\" marginheight=\"5\" leftmargin=\"5\" topmargin=\"5\"",
    "body"        => "",
    "section"     => "",
    @_
  );

  my $Return;
  if (!$in{'section'} || $in{'section'} eq "header") {
    $Return  = qq~<html>\n\n~;
    $Return .= qq~<head>\n~;

    foreach my $meta (@{ $in{'metas'} }) {
      $Return .= qq~<meta~;
      $Return .= qq~ http-equiv="$meta->{'http-equiv'}"~ if ($meta->{'http-equiv'});
      $Return .= qq~ name="$meta->{'name'}"~ if ($meta->{'name'});
      $Return .= qq~ content="$meta->{'content'}">\n~;
    }
  
    $Return .= qq~<title>$in{'title'}</title>\n~;
    $Return .= $in{'head-extra'};
    $Return .= qq~</head>\n\n~;
    $Return .= qq~<body~;
    $Return .= qq~ class="$in{'body-class'}"~ if ($in{'body-class'});
    $Return .= qq~ style="$in{'body-style'}"~ if ($in{'body-style'});
    $Return .= qq~ $in{'body-extra'}~ if ($in{'body-extra'});
    $Return .= qq~>\n\n~;
  }
  
  $Return .= $in{'body'};
  
  if (!$in{'section'} || $in{'section'} eq "footer") {
    $Return .= qq~\n~;
    $Return .= qq~</body>\n\n~;
    $Return .= qq~</html>\n~;
  }
  
  return $Return;
}

###############################################################################
# Form subroutine
sub Form {
  my $self = shift;
  
  my $Form = HTML::Form->new();

  return $Form->Form(@_);
}

###############################################################################
# Body subroutine
sub Body {
  my $self = shift;
  my ($body) = @_;
  
  my $Return  = qq~<table border="0" cellpadding="1" cellspacing="0" width="100%" class="border">\n~;
     $Return .= qq~  <tr>\n~;
     $Return .= qq~    <td>\n~;
     $Return .= qq~      <table border="0" cellpadding="3" cellspacing="1" width="100%" class="body">\n~;
     $Return .= $body;
     $Return .= qq~      </table>\n~;
     $Return .= qq~    </td>\n~;
     $Return .= qq~  </tr>\n~;
     $Return .= qq~</table>\n~;
  
  return $Return;
}

###############################################################################
# SmallHeader subroutine
sub SmallHeader {
  my $self = shift;
  my %in = (
    "titles"  => undef,
    "colspan" => 1,
    @_
  );

  my $Return  = qq~        <tr class="small-header">\n~;

  if (ref($in{'titles'}) eq "ARRAY") {
    foreach my $title (@{ $in{'titles'} }) {
      if (ref($title) eq "HASH") {
        $Return .= qq~          <td~;
        $Return .= qq~ colspan="$title->{'colspan'}"~ if ($title->{'colspan'} > 1);
        $Return .= qq~ width="$title->{'width'}"~ if ($title->{'width'});
        $Return .= qq~ nowrap~ if ($title->{'nowrap'});
        $Return .= qq~><font class="small-header">$title->{'text'}</font></td>\n~;
      } else {      
        $Return .= qq~          <td><font class="small-header">$title</font></td>\n~;
      }
    }
  } else {
    $Return .= qq~          <td~;
    $Return .= qq~ colspan="$in{'colspan'}"~ if ($in{'colspan'} > 1);
    $Return .= qq~><font class="small-header">$in{'titles'}</font></td>\n~;
  }

  $Return .= qq~        </tr>\n~;
  
  return $Return;
}

###############################################################################
# LargeHeader subroutine
sub LargeHeader {
  my $self = shift;
  my %in = (
    "title"   => "",
    "colspan" => 1,
    @_
  );

  my $Return  = qq~        <tr class="large-header">\n~;
     $Return .= qq~          <td~;
     $Return .= qq~ colspan="$in{'colspan'}"~ if ($in{'colspan'} > 1);
     $Return .= qq~><font class="large-header">$in{'title'}</font></td>\n~;
     $Return .= qq~        </tr>\n~;
  
  return $Return;
}

###############################################################################
# Row subroutine
sub Row {
  my $self = shift;
  my %in = (
    "fields"  => undef,
    "colspan" => 1,
    @_
  );

  my $Return  = qq~        <tr class="row">\n~;

  if (ref($in{'fields'}) eq "ARRAY") {
    foreach my $field (@{ $in{'fields'} }) {
      if (ref($field) eq "HASH") {
        $Return .= qq~          <td~;
        $Return .= qq~ colspan="$field->{'colspan'}"~ if ($field->{'colspan'} > 1);
        $Return .= qq~><font class="row">$field->{'text'}</font></td>\n~;
      } else {
        $Return .= qq~          <td><font class="row">$field</font></td>\n~;
      }
    }
  } else {
    $Return .= qq~          <td~;
    $Return .= qq~ colspan="$in{'colspan'}"~ if ($in{'colspan'} > 1);
    $Return .= qq~><font class="row">$in{'fields'}</font></td>\n~;
  }

  $Return .= qq~        </tr>\n~;
  
  return $Return;
}

###############################################################################
# Dialog subroutine
sub Dialog {
  my $self = shift;
  my %in = (
    "body"    => "",
    "colspan" => 1,
    @_
  );

  my $Return  = qq~        <tr class="body">\n~;
     $Return .= qq~          <td~;
     $Return .= qq~ colspan="$in{'colspan'}"~ if ($in{'colspan'} > 1);
     $Return .= qq~>\n~;
     $Return .= qq~            <table border="0" cellpadding="0" cellspacing="0" width="100%">\n~;
     $Return .= $in{'body'};
     $Return .= qq~            </table>\n~;
     $Return .= qq~          </td>\n~;
     $Return .= qq~        </tr>\n~;
  
  return $Return;
}

###############################################################################
# Text subroutine
sub Text {
  my $self = shift;
  my %in = (
    "text"    => "",
    @_
  );
  
  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td><font class="body">$in{'text'}</font></td>\n~;
     $Return .= qq~                    </tr>\n~;
     $Return .= qq~                  </table>\n~;
     $Return .= qq~                </td>\n~;
     $Return .= qq~              </tr>\n~;
  
  return $Return;
}

###############################################################################
# TextBox subroutine
sub TextBox {
  my $self = shift;
  my %in = (
    "name"    => "",
    "value"   => "",
    "subject" => "",
    "sub-subject" => "",
    "sub-field"   => "",
    "help"        => "",
    "required"    => 0,
    "password"    => 0,
    "file"        => 0,
    "iconhelp"    => "",
    "extra"       => "",
    @_
  );

  my $Form = HTML::Form->new();

  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td width="200" valign="top" nowrap><font class="subject">$in{'subject'}~;
     $Return .= qq~ <font color="Red"><b>*</b></font>~ if ($in{'required'});
     $Return .= qq~</font>~;
     $Return .= qq~<br><font class="sub-subject">$in{'sub-subject'}</font>~ if ($in{'sub-subject'});
     $Return .= qq~</td>\n~;
     $Return .= qq~                      <td width="~.($in{'help'} ? "60%" : "100%").qq~" valign="top">~;

  if ($in{'name'}) {
    $Return .= $Form->TextBox(name => $in{'name'}, value => $in{'value'}, password => $in{'password'}, file => $in{'file'}, extra => $in{'extra'});
  } else {
    $Return .= qq~<font class="textbox">$in{'value'}</font>~;
  }
  
  $Return .= qq~<br><font class="sub-field">$in{'sub-field'}</font>~ if ($in{'sub-field'});
  $Return .= qq~</td>\n~;

  $Return .= qq~                      <td width="40%"><font class="help">$in{'help'}</font></td>\n~ if ($in{'help'});
  $Return .= qq~                      <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/question.gif" border="0" alt="$in{'iconhelp'}"></td>\n~ if ($in{'iconhelp'});
  $Return .= qq~                    </tr>\n~;
  $Return .= qq~                  </table>\n~;
  $Return .= qq~                </td>\n~;
  $Return .= qq~              </tr>\n~;
  
  return $Return;
}

###############################################################################
# TextArea subroutine
sub TextArea {
  my $self = shift;
  my %in = (
    "name"        => "",
    "value"       => "",
    "subject"     => "",
    "sub-subject" => "",
    "sub-field"   => "",
    "help"        => "",
    "required"    => 0,
    "rows"        => 1,
    "iconhelp"    => "",
    "extra"       => "",
    @_
  );

  my $Form = HTML::Form->new();

  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td width="200" valign="top" nowrap><font class="subject">$in{'subject'}~;
     $Return .= qq~ <font color="Red"><b>*</b></font>~ if ($in{'required'});
     $Return .= qq~</font>~;
     $Return .= qq~<br><font class="sub-subject">$in{'sub-subject'}</font>~ if ($in{'sub-subject'});
     $Return .= qq~</td>\n~;
     $Return .= qq~                      <td width="~.($in{'help'} ? "60%" : "100%").qq~" valign="top">~;

  if ($in{'name'}) {
    $Return .= $Form->TextArea(name => $in{'name'}, value => $in{'value'}, rows => $in{'rows'}, extra => $in{'extra'});
  } else {
    $Return .= qq~<font class="textarea">$in{'value'}</font>~;
  }

  $Return .= qq~<br><font class="sub-field">$in{'sub-field'}</font>~ if ($in{'sub-field'});
  $Return .= qq~</td>\n~;

  $Return .= qq~                      <td width="40%"><font class="help">$in{'help'}</font></td>\n~ if ($in{'help'});
  $Return .= qq~                      <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/question.gif" border="0" alt="$in{'iconhelp'}"></td>\n~ if ($in{'iconhelp'});
  $Return .= qq~                    </tr>\n~;
  $Return .= qq~                  </table>\n~;
  $Return .= qq~                </td>\n~;
  $Return .= qq~              </tr>\n~;

  return $Return;
}

###############################################################################
# Radio subroutine
sub Radio {
  my $self = shift;
  my %in = (
    "name"        => "",
    "value"       => "",
    "subject"     => "",
    "sub-subject" => "",
    "sub-field"   => "",
    "help"        => "",
    "radios"      => [ ], # value, label
    "join"        => "",
    "required"    => 0,
    "iconhelp"    => "",
    "extra"       => "",
    @_
  );

  my $Form = HTML::Form->new();

  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td width="200" valign="top" nowrap><font class="subject">$in{'subject'}~;
     $Return .= qq~ <font color="Red"><b>*</b></font>~ if ($in{'required'});
     $Return .= qq~</font>~;
     $Return .= qq~<br><font class="sub-subject">$in{'sub-subject'}</font>~ if ($in{'sub-subject'});
     $Return .= qq~</td>\n~;
     $Return .= qq~                      <td width="~.($in{'help'} ? "60%" : "100%").qq~">~;

  if ($in{'name'}) {
    foreach my $radio (@{ $in{'radios'} }) {
      $radio->{'name'} = $in{'name'};
      $radio->{'checked'} = 1 if ($in{'value'} eq $radio->{'value'});
    }
    $Return .= $Form->Radio(radios => $in{'radios'}, join => $in{'join'}, extra => $in{'extra'});
  } else {
    my $value;
    foreach my $radio (@{ $in{'radios'} }) {
      $value = $radio->{'label'} if ($radio->{'value'} == $in{'value'});
    }
    $Return .= qq~<font class="radio">$value</font>~;
  }

  $Return .= qq~<br><font class="sub-field">$in{'sub-field'}</font>~ if ($in{'sub-field'});
  $Return .= qq~</td>\n~;

  $Return .= qq~                      <td width="40%"><font class="help">$in{'help'}</font></td>\n~ if ($in{'help'});
  $Return .= qq~                      <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/question.gif" border="0" alt="$in{'iconhelp'}"></td>\n~ if ($in{'iconhelp'});
  $Return .= qq~                    </tr>\n~;
  $Return .= qq~                  </table>\n~;
  $Return .= qq~                </td>\n~;
  $Return .= qq~              </tr>\n~;

  return $Return;
}

###############################################################################
# CheckBox subroutine
sub CheckBox {
  my $self = shift;
  my %in = (
    "name"        => "",
    "value"       => undef,
    "subject"     => "",
    "sub-subject" => "",
    "sub-field"   => "",
    "help"        => "",
    "checkboxes"  => [ ], # value, label
    "join"        => "",
    "required"    => 0,
    "iconhelp"    => "",
    "extra"       => "",
    @_
  );

  my $Form = HTML::Form->new();

  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td width="200" valign="top" nowrap><font class="subject">$in{'subject'}~;
     $Return .= qq~ <font color="Red"><b>*</b></font>~ if ($in{'required'});
     $Return .= qq~</font>~;
     $Return .= qq~<br><font class="sub-subject">$in{'sub-subject'}</font>~ if ($in{'sub-subject'});
     $Return .= qq~</td>\n~;
     $Return .= qq~                      <td width="~.($in{'help'} ? "60%" : "100%").qq~">~;

  my %values;
  if (ref($in{'value'}) eq "ARRAY") {
    foreach my $value (@{ $in{'value'} }) {
      $values{ $value } = 1;
    }
  } elsif (ref($in{'value'}) eq "HASH") {
    %values = %{ $in{'value'} };
  } else {
    $values{ $in{'value'} } = 1;
  }

  if ($in{'name'}) {
    foreach my $checkbox (@{ $in{'checkboxes'} }) {
      $checkbox->{'name'} = $in{'name'};
      $checkbox->{'checked'} = 1 if ($values{ $checkbox->{'value'} });
    }
    $Return .= $Form->CheckBox(checkboxes => $in{'checkboxes'}, join => $in{'join'}, extra => $in{'extra'});
  } else {
    my @values;
    foreach my $checkbox (@{ $in{'checkboxes'} }) {
      push(@values, qq~<font class="checkbox">$checkbox->{'label'}</font>~) if ($values{ $checkbox->{'value'} });
    }
    $Return .= join($in{'join'}, @values);
  }

  $Return .= qq~<br><font class="sub-field">$in{'sub-field'}</font>~ if ($in{'sub-field'});
  $Return .= qq~</td>\n~;

  $Return .= qq~                      <td width="40%"><font class="help">$in{'help'}</font></td>\n~ if ($in{'help'});
  $Return .= qq~                      <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/question.gif" border="0" alt="$in{'iconhelp'}"></td>\n~ if ($in{'iconhelp'});
  $Return .= qq~                    </tr>\n~;
  $Return .= qq~                  </table>\n~;
  $Return .= qq~                </td>\n~;
  $Return .= qq~              </tr>\n~;

  return $Return;
}

###############################################################################
# SelectBox subroutine
sub SelectBox {
  my $self = shift;
  my %in = (
    "name"        => "",
    "value"       => undef,
    "subject"     => "",
    "sub-subject" => "",
    "sub-field"   => "",
    "help"        => "",
    "options"     => [ ], # value, text
    "join"        => "",
    "size"        => 1,
    "multiple"    => 0,
    "required"    => 0,
    "iconhelp"    => "",
    "extra"       => "",
    @_
  );

  my $Form = HTML::Form->new();

  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td width="200" valign="top" nowrap><font class="subject">$in{'subject'}~;
     $Return .= qq~ <font color="Red"><b>*</b></font>~ if ($in{'required'});
     $Return .= qq~</font>~;
     $Return .= qq~<br><font class="sub-subject">$in{'sub-subject'}</font>~ if ($in{'sub-subject'});
     $Return .= qq~</td>\n~;
     $Return .= qq~                      <td width="~.($in{'help'} ? "60%" : "100%").qq~">~;

  my %values;
  if (ref($in{'value'}) eq "ARRAY") {
    foreach my $value (@{ $in{'value'} }) {
      $values{ $value } = 1;
    }
  } elsif (ref($in{'value'}) eq "HASH") {
    %values = %{ $in{'value'} };
  } else {
    $values{ $in{'value'} } = 1;
  }

  if ($in{'name'}) {
    foreach my $option (@{ $in{'options'} }) {
      $option->{'selected'} = 1 if ($values{ $option->{'value'} });
    }
    $Return .= $Form->SelectBox(name => $in{'name'}, size => $in{'size'}, multiple => $in{'multiple'}, options => $in{'options'}, extra => $in{'extra'});
  } else {
    my @values;
    foreach my $option (@{ $in{'options'} }) {
      push(@values, qq~<font class="selectbox">$option->{'text'}</font>~) if ($values{ $option->{'value'} });
    }
    $Return .= join("<br>", @values);
  }

  $Return .= qq~<br><font class="sub-field">$in{'sub-field'}</font>~ if ($in{'sub-field'});
  $Return .= qq~</td>\n~;

  $Return .= qq~                      <td width="40%"><font class="help">$in{'help'}</font></td>\n~ if ($in{'help'});
  $Return .= qq~                      <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/question.gif" border="0" alt="$in{'iconhelp'}"></td>\n~ if ($in{'iconhelp'});
  $Return .= qq~                    </tr>\n~;
  $Return .= qq~                  </table>\n~;
  $Return .= qq~                </td>\n~;
  $Return .= qq~              </tr>\n~;

  return $Return;
}

###############################################################################
# Button subroutine
sub Button {
  my $self = shift;
  my %in = (
    "subject"     => "",
    "sub-subject" => "",
    "sub-field"   => "",
    "help"        => "",
    "buttons"     => [ ], # type, name, value
    "join"        => "",
    "iconhelp"    => "",
    "extra"       => "",
    @_
  );

  my $Form = HTML::Form->new();

  my $Return .= qq~              <tr>\n~;
     $Return .= qq~                <td>\n~;
     $Return .= qq~                  <table border="0" cellpadding="3" cellspacing="1" width="100%">\n~;
     $Return .= qq~                    <tr>\n~;
     $Return .= qq~                      <td width="200" valign="top" nowrap><font class="subject">$in{'subject'}~;
     $Return .= qq~ <font color="Red"><b>*</b></font>~ if ($in{'required'});
     $Return .= qq~</font>~;
     $Return .= qq~<br><font class="sub-subject">$in{'sub-subject'}</font>~ if ($in{'sub-subject'});
     $Return .= qq~</td>\n~;
     $Return .= qq~                      <td width="~.($in{'help'} ? "60%" : "100%").qq~">~;

     $Return .= $Form->Button(buttons => $in{'buttons'}, join => $in{'join'}, extra => $in{'extra'});

     $Return .= qq~                      <td width="40%"><font class="help">$in{'help'}</font></td>\n~ if ($in{'help'});
     $Return .= qq~                      <td width="1" nowrap><img src="http://www.plasmapulse.com/images/offsite/question.gif" border="0" alt="$in{'iconhelp'}"></td>\n~ if ($in{'iconhelp'});
     $Return .= qq~                    </tr>\n~;
     $Return .= qq~                  </table>\n~;
     $Return .= qq~                </td>\n~;
     $Return .= qq~              </tr>\n~;

  return $Return;
}

1;