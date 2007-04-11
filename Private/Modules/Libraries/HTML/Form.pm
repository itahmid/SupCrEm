###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/Form.pm.pl -> Form HTML module                                        #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package HTML::Form;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless($self, $class);
}

sub DESTROY { }

###############################################################################
# Form subroutine
sub Form {
  my $self = shift;
  my %in = (
    "name"    => "form",
    "method"  => "POST",
    "action"  => $SYSTEM->{'SCRIPT_URL'},
    "body"    => "",
    "extra"   => "",
    "hiddens" => [ ], # name, value, extra
    @_
  );
  
  my $Return  = qq~<form name="$in{'name'}" method="$in{'method'}" action="$in{'action'}"~;
     $Return .= qq~ $in{'extra'}~ if ($in{'extra'});
     $Return .= qq~>~;
  
  foreach my $hidden (@{ $in{'hiddens'} }) {
    $Return .= qq~<input type="hidden" name="$hidden->{'name'}" value="$hidden->{'value'}"~;
    $Return .= qq~ $hidden->{'extra'}~ if ($hidden->{'extra'});
    $Return .= qq~>~;
  }
  
  $Return .= qq~\n~;
  $Return .= $in{'body'};
  $Return .= qq~</form>\n~;
  
  return $Return;   
}

###############################################################################
# TextBox subroutine
sub TextBox {
  my $self = shift;
  my %in = (
    "name"      => "",
    "value"     => "",
    "class"     => "textbox",
    "style"     => "",
    "extra"     => "",
    "password"  => 0,
    "file"      => 0,
    @_
  );
  
  my $Return  = qq~<input type="~;

  if ($in{'password'}) {
    $Return .= qq~password~;
  } elsif ($in{'file'}) {
    $Return .= qq~file~;
  } else {
    $Return .= qq~text~;
  }

  $Return .= qq~" name="$in{'name'}" value="$in{'value'}" class="$in{'class'}"~;
  $Return .= qq~ style="$in{'style'}"~ if ($in{'style'});
  $Return .= qq~ $in{'extra'}~ if ($in{'extra'});
  $Return .= qq~>~;
  
  return $Return;
}

###############################################################################
# TextArea subroutine
sub TextArea {
  my $self = shift;
  my %in = (
    "name"  => "",
    "value" => "",
    "class" => "textarea",
    "style" => "",
    "extra" => "",
    "rows"  => 1,
    @_
  );
  
  my $Return  = qq~<textarea name="$in{'name'}" rows="$in{'rows'}" class="$in{'class'}"~;
     $Return .= qq~ style="$in{'style'}"~ if ($in{'style'});
     $Return .= qq~ $in{'extra'}~ if ($in{'extra'});
     $Return .= qq~>$in{'value'}</textarea>~;
  
  return $Return;
}

###############################################################################
# Radio subroutine
sub Radio {
  my $self = shift;
  my %in = (
    "radios"  => [ ], # name, value, checked, class, style, extra, label
    "join"    => "",
    @_
  );
  
  my @radios;
  foreach my $radio (@{ $in{'radios'} }) {
    my $Radio  = qq~<input type="radio" name="$radio->{'name'}" value="$radio->{'value'}"~;
       $Radio .= qq~ checked~ if ($radio->{'checked'});
       $Radio .= qq~ class="$radio->{'class'}"~ if ($radio->{'class'});
       $Radio .= qq~ style="$radio->{'style'}"~ if ($radio->{'style'});
       $Radio .= qq~ $radio->{'extra'}~ if ($radio->{'extra'});
       $Radio .= qq~>~;
       $Radio .= qq~ <font class="label">$radio->{'label'}</font>~ if ($radio->{'label'});
    push(@radios, $Radio);
  }
  
  return join($in{'join'}, @radios);
}

###############################################################################
# CheckBox subroutine
sub CheckBox {
  my $self = shift;
  my %in = (
    "checkboxes"  => [ ], # name, value, checked, class, style, extra, label
    "join"        => "",
    @_
  );
  
  my @checkboxes;
  foreach my $checkbox (@{ $in{'checkboxes'} }) {
    my $CheckBox  = qq~<input type="checkbox" name="$checkbox->{'name'}" value="$checkbox->{'value'}"~;
       $CheckBox .= qq~ checked~ if ($checkbox->{'checked'});
       $CheckBox .= qq~ class="$checkbox->{'class'}"~ if ($checkbox->{'class'});
       $CheckBox .= qq~ style="$checkbox->{'style'}"~ if ($checkbox->{'style'});
       $CheckBox .= qq~ $checkbox->{'extra'}~ if ($checkbox->{'extra'});
       $CheckBox .= qq~>~;
       $CheckBox .= qq~ <font class="label">$checkbox->{'label'}</font>~ if ($checkbox->{'label'});
    push(@checkboxes, $CheckBox);
  }
  
  return join($in{'join'}, @checkboxes);
}

###############################################################################
# SelectBox subroutine
sub SelectBox {
  my $self = shift;
  my %in = (
    "name"      => "",
    "size"      => 1,
    "multiple"  => 0,
    "class"     => "selectbox",
    "style"     => "",
    "extra"     => "",
    "options"   => [ ], # value, selected, text
    @_
  );

  my $Return  = qq~<select name="$in{'name'}" size="$in{'size'}"~;
     $Return .= qq~ multiple~ if ($in{'multiple'});
     $Return .= qq~ class="$in{'class'}"~;
     $Return .= qq~ style="$in{'style'}"~ if ($in{'style'});
     $Return .= qq~ $in{'extra'}~ if ($in{'extra'});
     $Return .= qq~>~;
  
  foreach my $option (@{ $in{'options'} }) {
    $Return .= qq~<option value="$option->{'value'}"~;
    $Return .= qq~ selected~ if ($option->{'selected'});
    $Return .= qq~>$option->{'text'}</option>~;
  }
  
  $Return .= qq~</select>~;
  
  return $Return;
}

###############################################################################
# Button subroutine
sub Button {
  my $self = shift;
  my %in = (
    "buttons"     => [ ], # type, name, value, class, style, extra
    "join"        => "",
    @_
  );
  
  my @buttons;
  foreach my $button (@{ $in{'buttons'} }) {
    my $Button  = qq~<input type="$button->{'type'}" name="$button->{'name'}" value="$button->{'value'}"~;
       $Button .= qq~ class="$button->{'class'}"~ if ($button->{'class'});
       $Button .= qq~ style="$button->{'style'}"~ if ($button->{'style'});
       $Button .= qq~ $button->{'extra'}~ if ($button->{'extra'});
       $Button .= qq~>~;
    push(@buttons, $Button);
  }

  return join($in{'join'}, @buttons);
}

1;