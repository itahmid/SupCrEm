###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Variables.pm -> Variables library                                           #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Variables;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless ($self, $class);
}

sub DESTROY {}

###############################################################################
# Update subroutine
sub Update {
  my $self = shift;
  my %in = (FILE => "", PACKAGE => "", VARIABLE => "", VALUES => {}, @_);
  
  foreach my $field ("FILE", "PACKAGE", "VARIABLE", "VALUES") {
    unless ($in{$field}) {
      $self->{'ERROR'} = "No $field specified";
      return;
    }
  }
  
  require $in{'FILE'} || ($self->{'ERROR'} = "Couldn't require FILE. $!" and return);
  eval "import $in{'PACKAGE'} qw(\$$in{'VARIABLE'})";
  $self->{'ERROR'} = "Couldn't import VARIABLE. $@" and return if ($@);
  
  my $VARIABLE = eval "return \$$in{'VARIABLE'}";
  
  my $NewFile = <<TEXT;
###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg\@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
TEXT

  my $Space = " " x (50 - (length($in{'PACKAGE'}) * 2));
  $NewFile .= qq~# $in{'PACKAGE'}.pm.pl -> $in{'PACKAGE'} variable module$Space#\n~;
  
  $NewFile .= <<TEXT;
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package $in{'PACKAGE'};

require Exporter;

\@ISA       = qw(Exporter);
\@EXPORT    = qw(\@EXPORT_OK);
\@EXPORT_OK = qw(\$$in{'VARIABLE'});

use strict;
use vars qw(\$$in{'VARIABLE'});

\$$in{'VARIABLE'} = {
TEXT

  my @Keys = sort keys(%{ $VARIABLE });
  for (my $h = 0; $h <= $#Keys; $h++) {
    my $key = $Keys[$h];
    my $value = $in{'VALUES'}->{$key};

    $Space = " " x (26 - length($key));

    if (ref($VARIABLE->{$key}) eq "ARRAY") {
      my @array;
      if ($value) {
        @array = @{$value};
      } else {
        @array = @{$VARIABLE->{$key}};
      }

      $NewFile .= qq~  "$key"$Space=> [~;
      for (my $i = 0; $i <= $#array; $i++) {
        $array[$i] =~ s/\@/\\\@/g;
        $NewFile .= qq~"$array[$i]"~;
        $NewFile .= qq~, ~ unless ($i == $#array);
      }
      $NewFile .= qq~]~;
    } elsif (ref($VARIABLE->{$key}) eq "HASH") {
      my %hash;
      if ($value) {
        %hash = %{$value};
      } else {
        %hash = %{$VARIABLE->{$key}};
      }
      my @keys = sort keys(%hash);

      $NewFile .= qq~  "$key"$Space=> {\n~;
      for (my $i = 0; $i <= $#keys; $i++) {
        my $key = $keys[$i];
           $key =~ s/\@/\\\@/g;
        my $value = $hash{ $keys[$i] };
           $value =~ s/\@/\\\@/g;
        $Space = " " x (26 - length($key));
        $NewFile .= qq~    "$key"$Space=> "$value"~;
        $NewFile .= qq~,~ unless ($i == $#keys);
        $NewFile .= qq~\n~;
      }
      $NewFile .= qq~  }~;
    } else {
      my $scalar;
      if ($value ne "") {
        $scalar = $value;
      } else {
        $scalar = $VARIABLE->{$key};
      }

      $scalar =~ s/\@/\\\@/g;
      $NewFile .= qq~  "$key"$Space=> "$scalar"~;
    }

    $NewFile .= qq~,~ unless ($h == $#Keys);
    $NewFile .= qq~\n~;
  }

  $NewFile .= <<TEXT;
};

1;
TEXT

  open(FILE, ">$in{'FILE'}") || ($self->{'ERROR'} = "Error opening FILE for writing. $!" and return);
  print FILE $NewFile;
  close(FILE);
  
  return 1;
}

1;