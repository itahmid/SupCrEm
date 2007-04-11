###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Standard.pm.pl -> Standard library                                          #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Standard;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";

use Template;
use strict;

###############################################################################
# Substitute subroutine
sub Substitute {
  my %in = (
    "STANDARD"	=> 0,
    "INPUT"     => "",
    "FIELDS"    => { },
    @_
  );

  my %Options;
  
  $Options{'INCLUDE_PATH'} = "$SD::PATH/Private/Skins/$SD::GLOBAL{'SKIN'}/Templates";
  $Options{'ABSOLUTE'}     = 1;
  $Options{'RELATIVE'}     = 1;
  $Options{'START_TAG'}    = quotemeta($SYSTEM->{'START_TAG'});
  $Options{'END_TAG'}      = quotemeta($SYSTEM->{'END_TAG'});
  
  if ($SYSTEM->{'CACHING'}) {
    $Options{'COMPILE_DIR'} = $SYSTEM->{'CACHE_PATH'};
    $Options{'COMPILE_EXT'} = ".ttc";
  }

  my $Template = Template->new(%Options);
  
  if ($in{'STANDARD'}) {
    require "Skins/$SD::GLOBAL{'SKIN'}/StyleSheet.pm.pl";
    my $STYLE = StyleSheet->new();

    $in{'FIELDS'}->{'system'} = $SYSTEM;
    $in{'FIELDS'}->{'general'} = $GENERAL;

    foreach my $key (keys %{ $STYLE }) {
      $in{'FIELDS'}->{'style'}->{$key} = $STYLE->{$key};
    }

    $in{'FIELDS'}->{'form'} = \%SD::QUERY;
    
    if ($in{'CP'} && %SD::ADMIN) {
      $in{'FIELDS'}->{'admin'} = \%SD::ADMIN;
    } elsif (!$in{'CP'} && %SD::USER) {
      $in{'FIELDS'}->{'user'} = {
        "account" => $SD::USER{'ACCOUNT'},
        "session" => $SD::USER{'SESSION'}
      };
    }

    $in{'FIELDS'}->{'global'} = \%SD::GLOBAL;
    
    foreach my $key (keys %SD::TAGS) {
      $in{'FIELDS'}->{$key} = $SD::TAGS{$key};
    }
  }

  my $Return;
  unless ($Template->process($in{'INPUT'}, $in{'FIELDS'}, \$Return)) {
    &Error::CGIError("Error processing template. ".&HTMLize($Template->error()), "");
  }
  
  return $Return;
}

###############################################################################
# ProcessPlugins subroutine
sub ProcessPlugins {
  
  opendir(PLUGINS, "$SD::PATH/Private/Plugins");
  foreach my $file (grep(/\.(pm|pl)$/, readdir(PLUGINS))) {
#    my $eval  = "require \"$SD::PATH/Private/Plugins/$file\";";
#       $eval .= "return Plugin->new();";
#    my $Plugin = eval($eval);    
#    my $Plugin = eval {
#      require "$SD::PATH/Private/Plugins/$file";
#      return Plugin->new();
#    };
    eval {
      require "$SD::PATH/Private/Plugins/$file";
      my $Plugin = Plugin->new();
      return unless ($Plugin);
    
      foreach my $key (keys %{ $Plugin->{'TAGS'} }) {
        $SD::TAGS{$key} = $Plugin->{'TAGS'}->{$key};
      }
      foreach my $key (keys %{ $Plugin->{'ACTIONS'}->{'SD'} }) {
        $SD::ACTIONS{'SD'}->{$key} = $Plugin->{'ACTIONS'}->{'SD'}->{$key};
      }
      foreach my $key (keys %{ $Plugin->{'ACTIONS'}->{'CP'} }) {
        $SD::ACTIONS{'CP'}->{$key} = $Plugin->{'ACTIONS'}->{'CP'}->{$key};
      }
      foreach my $key (keys %{ $Plugin->{'CPMENU'} }) {
        if ($SD::CPMENU{$key}) {
          if (ref($SD::CPMENU{$key}->[2]) ne "ARRAY") {
            push(@{ $SD::CPMENU{$key} }, @{ $Plugin->{'CPMENU'}->{$key} });
          } else {
            if (ref($Plugin->{'CPMENU'}->{$key}->[2]) ne "ARRAY") {
              push(@{ $SD::CPMENU{$key}->[2] }, @{ $Plugin->{'CPMENU'}->{$key} });
            } else {
              push(@{ $SD::CPMENU{$key}->[2] }, @{ $Plugin->{'CPMENU'}->{$key}->[2] });
            }
          }
        } else {
          $SD::CPMENU{$key} = $Plugin->{'CPMENU'}->{$key};
        }
      }
    };
  }
  closedir(DIR);
  
  return 1;
}

###############################################################################
# FileOpen function
sub FileOpen {
  my ($FileHandle, $AccessMode, $FileName, $skip) = @_;
  $FileName   =~ s/\|//g;
  $FileName   =~ s/\>//g;
  $FileName   =~ s/\<//g;

  $FileName =~ /^(.+)\/[^\/]+$/;
  my $Path = $1;

  my $Mode;
  if ($AccessMode eq "a") {
    if (-e $FileName) {
      $Mode = ">>";
    } else {
      $Mode = ">";
    }
  } elsif ($AccessMode eq "w") {
    $Mode = ">";
  } elsif ($AccessMode eq "r") {
    $Mode = "";
  } elsif ($AccessMode eq "rw") {
    unless (-e $FileName) {
      open ($FileHandle, ">".$FileName);
      close ($FileHandle);
    }
    $Mode = "";
  }

  chmod (0777, $FileName);

  unless (open ($FileHandle, $Mode.$FileName)) {
    if ($AccessMode eq "a") {
      &Error::CGIError("Can't open file for appending. $!", $FileName) unless $skip;
      return;
    } elsif ($AccessMode eq "w") {
      &Error::CGIError("Can't open file for writing. $!"  , $FileName) unless $skip;
      return;
    } elsif ($AccessMode eq "r") {
      &Error::CGIError("Can't open file for reading. $!"  , $FileName) unless $skip;
      return;
    }
  }

  chmod (0766, $FileName);

  if ($SYSTEM->{'FLOCK'} == 1) {
    if ($AccessMode ne "r") {
      flock ($FileHandle, 2);
    } else {
      flock ($FileHandle, 1);
    }
  }

  return 1;
}

###############################################################################
# lock function
sub lock {
  my ($file)  = @_;
  my $EndTime = 30 + time;

  while ((-e $file) && (time < $EndTime)) {
    sleep(1);
  }

  chmod (0777, $SYSTEM->{'TEMP_PATH'});

  open(LOCK, ">$SYSTEM->{'TEMP_PATH'}/$file") || &Error::CGIError("Can't open a file for locking. $!", "$SYSTEM->{'TEMP_PATH'}/$file");
  chmod (0777, "$SYSTEM->{'TEMP_PATH'}/$file");
}

###############################################################################
# unLock function
sub unLock {
  my ($file) = @_;

  close(LOCK);

  unlink("$SYSTEM->{'TEMP_PATH'}/$file");
}

###############################################################################
# PrintHTMLHeader function
sub PrintHTMLHeader {
  return if ($SD::HTML_HEADER);

  if ($SD::CGI) {
    my $Path = $SYSTEM->{'SCRIPT_URL'};
       $Path =~ s/^http(s)?\:\/\/(.*?)\//\//;
    my $Cookie = $SD::CGI->cookie(
      -name     => "SuperDesk",
      -value    => \%SD::COOKIES,
      -expires  => "+30d",
      -path     => $Path
    );

    print $SD::CGI->header(-cookie => $Cookie);
  } else {
    print "Content-Type: text/html\n\n";
  }
  
  $SD::HTML_HEADER = 1;
}

###############################################################################
# ParseForm function
sub ParseForm {
  foreach my $keyword ($SD::CGI->param()) {
    $SD::QUERY{ $keyword } = $SD::CGI->param( $keyword );
  }
}

###############################################################################
# ParseCookies function
sub ParseCookies {
  %SD::COOKIES = $SD::CGI->cookie("SuperDesk");
}

###############################################################################
# SetSkin function
sub SetSkin {
  if ($SD::QUERY{'Skin'} && (-e "$SD::PATH/Private/Skins/$SD::QUERY{'Skin'}.cfg")) {
    $SD::GLOBAL{'SKIN'}  = $SD::QUERY{'Skin'};
    $SD::COOKIES{'SKIN'} = $SD::QUERY{'Skin'};
  } elsif ($SD::COOKIES{'SKIN'} && (-e "$SD::PATH/Private/Skins/$SD::COOKIES{'SKIN'}.cfg")) {
    $SD::GLOBAL{'SKIN'} = $SD::COOKIES{'SKIN'};
  } else {
    $SD::GLOBAL{'SKIN'} = $GENERAL->{'SKIN'};
  }
}

###############################################################################
# ProcessError function
sub ProcessError {
  my %in = (LANGUAGE => undef, ERROR => undef, @_);

  return unless ($in{'ERROR'});

  my $LANGUAGE;
  
  if (ref($in{'LANGUAGE'}) eq "HASH") {
    $LANGUAGE = $in{'LANGUAGE'};
  } else {
    $LANGUAGE = &GetLanguage($in{'LANGUAGE'});
  }

  $in{'ERROR'} = [$in{'ERROR'}] unless (ref($in{'ERROR'}) eq "ARRAY");

  my $Return;
  foreach my $Error (@{ $in{'ERROR'} }) {
    if ($Error =~ /^MISSING-(.*)$/ && $LANGUAGE->{'MISSING'}->{ $1 }) {
      $Return .= $LANGUAGE->{'MISSING'}->{ $1 };
    } elsif ($Error =~ /^INVALID-(.*)$/ && $LANGUAGE->{'INVALID'}->{ $1 }) {
      $Return .= $LANGUAGE->{'INVALID'}->{ $1 };
    } elsif ($Error =~ /^TOOLONG-(.*)$/ && $LANGUAGE->{'TOOLONG'}->{ $1 }) {
      $Return .= $LANGUAGE->{'TOOLONG'}->{ $1 };
    } elsif ($Error =~ /^ALREADYEXISTS-(.*)$/ && $LANGUAGE->{'ALREADYEXISTS'}->{ $1 }) {
      $Return .= $LANGUAGE->{'ALREADYEXISTS'}->{ $1 };
    } elsif ($LANGUAGE->{ $Error }) {
      $Return .= $LANGUAGE->{ $Error };
    }
  }

  return unless ($Return);

  return &Substitute(
    INPUT     => \$LANGUAGE->{'ERROR'},
    STANDARD  => 1,
    FIELDS    => { error => $Return }
  );
}

###############################################################################
# GetLanguage function
sub GetLanguage {
  my ($Language) = @_;

  if ($Language =~ /^CP\:\:(.*)$/) {
    require "Skins/$SD::GLOBAL{'SKIN'}/Language/ControlPanel/".$1.".lang";
  } else {
    require "Skins/$SD::GLOBAL{'SKIN'}/Language/".$Language.".lang";
  }

  return eval("return \$Language::".$Language."::LANGUAGE");
}

###############################################################################
# ConvertEpochToDate function
sub ConvertEpochToDate {
  my ($Epoch) = @_;

  $Epoch = time unless ($Epoch);

  my @Months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
  my ($mDay, $mon, $year, $isdst);

  if ($SYSTEM->{'LOCALTIME_OFFSET'} && $SYSTEM->{'LOCALTIME'} ne "0") {
    (undef, undef, undef, $mDay, $mon, $year, undef, undef, $isdst) = localtime($Epoch + ($SYSTEM->{'LOCALTIME_OFFSET'} * 60 * 60));
  } else {
    (undef, undef, undef, $mDay, $mon, $year, undef, undef, $isdst) = localtime($Epoch);
  }

  my $Date;

  $year += 1900;

  if ($GENERAL->{'DATE_FORMAT'} eq "US") {
    $Date = sprintf ("%02d-%02d-%04d", $mon + 1, $mDay, $year);
  } elsif ($GENERAL->{'DATE_FORMAT'} eq "USE") {
    $Date = sprintf ("%s %02d, %04d", $Months[$mon], $mDay, $year);
  } elsif ($GENERAL->{'DATE_FORMAT'} eq "EU") {
    $Date = sprintf ("%02d-%02d-%04d", $mDay, $mon + 1, $year);
  } elsif ($GENERAL->{'DATE_FORMAT'} eq "EUE") {
    $Date = sprintf ("%02d %s, %04d", $mDay, $Months[$mon], $year);
  } else {
    $Date = sprintf ("%02d-%02d-%04d", $mon + 1, $mDay, $year);
  }

  return $Date;
}

###############################################################################
# ConvertEpochToTime function
sub ConvertEpochToTime {
  my ($Epoch) = @_;

  $Epoch = time unless ($Epoch);

  my ($sec, $min, $hour, $isdst);

  if ($SYSTEM->{'LOCALTIME_OFFSET'} && $SYSTEM->{'LOCALTIME_OFFSET'} ne "0") {
    ($sec, $min, $hour, undef, undef, undef, undef, undef, $isdst) = localtime($Epoch + ($SYSTEM->{'LOCALTIME_OFFSET'} * 60 * 60));
  } else {
    ($sec, $min, $hour, undef, undef, undef, undef, undef, $isdst) = localtime($Epoch);
  }

  my $Time;
	
  if ($GENERAL->{'TIME_FORMAT'} eq "12") {
    if ($hour >= 12) {
      $hour -= 12 if ($hour > 12);
      $Time = sprintf ("%02d:%02d p.m.", $hour, $min);
    } else {
      $hour = 12 if ($hour == 0);
      $Time = sprintf ("%02d:%02d a.m.", $hour, $min);
    }
  } else {
    $Time = sprintf ("%02d:%02d", $hour, $min);
  }

  return $Time;
}

###############################################################################
# HTMLize function
sub HTMLize {
  my ($Data) = @_;

  $Data =~ s/\&/\&amp\;/g;
  $Data =~ s/\</\&lt\;/g;
  $Data =~ s/\>/\&gt\;/g;
  $Data =~ s/\"/\&quot\;/g;
  $Data =~ s/\'/\&#39\;/g;
  #$Data =~ s/\|/\&\#124\;/g;
  $Data =~ s/\r//g;

  return $Data;
}

1;