###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/ConvertDatabase.pm.pl -> ConvertDatabase module                #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::ConvertDatabase;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/ConvertDatabase.pm.pl";

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

  my @Databases;
  
  opendir(DIR, "$SD::PATH/Private/Modules/ControlPanel/Databases") || &Error::CGIError("Error opening directory. $!", "$SD::PATH/Private/Modules/ControlPanel/Databases");
  foreach my $file (grep(/\.pm$/, readdir(DIR))) {
    my $description = eval("require \"$SD::PATH/Private/Modules/ControlPanel/Databases/$file\"; my \$Source = CP::Database->new(); return \$Source->{'DB_NAME'};")
      || &Error::CGIError("Error evaluating database conversion module. $@", "$SD::PATH/Private/Modules/ControlPanel/Databases/$file");
    my $name = $file;
       $name =~ s/\.pm$//;
    push(@Databases, { NAME => $name, DESCRIPTION => $description });
  }
  closedir(DIR);

  my %INPUT;
  
  $INPUT{'DATABASES'} = \@Databases;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ConvertDatabase->new();

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

  if (!$SD::QUERY{'FORM_DATABASE'} || !(-e "$SD::PATH/Private/Modules/ControlPanel/Databases/$SD::QUERY{'FORM_DATABASE'}.pm")) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  require "$SD::PATH/Private/Modules/ControlPanel/Databases/$SD::QUERY{'FORM_DATABASE'}.pm";
  my $Source = CP::Database->new();
  
  my %INPUT;
  
  $INPUT{'DATABASE'} = {
    DESCRIPTION => $Source->{'DB_NAME'},
    NAME        => $SD::QUERY{'FORM_DATABASE'}
  };
  $INPUT{'FIELDS'} = $Source->{'FIELDS'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ConvertDatabase->new();

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

  if (!$SD::QUERY{'FORM_DATABASE'} || !(-e "$SD::PATH/Private/Modules/ControlPanel/Databases/$SD::QUERY{'FORM_DATABASE'}.pm")) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  require "$SD::PATH/Private/Modules/ControlPanel/Databases/$SD::QUERY{'FORM_DATABASE'}.pm";
  my $Source = CP::Database->new();

  my %Input;
  foreach my $field (@{ $Source->{'FIELDS'} }) {
    $Input{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
  }

  unless ($Source->check(DB => $in{'DB'}, INPUT => \%Input)) {
    $self->view(DB => $in{'DB'}, ERROR => $Source->{'ERROR'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::ConvertDatabase->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do("header");
  $Source->do($self, DB => $in{'DB'}, INPUT => \%Input);
  print $Skin->do("footer");  
  
  return 1;
}

###############################################################################
# Print subroutine
sub Print {
  my $self = shift;
  my $parent = shift;
  my ($message, $command) = @_;
  
  if ($command eq "uplevel") {
    $message = "<ul>";
  } elsif ($command eq "downlevel") {
    $message = "</ul>";
  } elsif ($command eq "element") {
    $message = "<li>$message";
  } elsif ($command eq "error") {
    $message = "<font color=\"Red\">$message</font>";
  } elsif ($command eq "success") {
    $message = "<font color=\"Green\">$message</font>";
  } elsif ($command eq "check") {
    $message = "<font color=\"Olive\">$message</font>";
  }

  $message =~ s/\n/\<br\>/g;
  
  $parent->{'LOG'} .= $message;
  
  $message =~ s/\"/\\\"/g;

  print <<HTML;
<script language="JavaScript">
  <!--
  document.LOG.document.write("$message");
  document.LOG.scrollTo(0, 9999999);
  //-->
</script>
HTML

  return 1;
}

1;