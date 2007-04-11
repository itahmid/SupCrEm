###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/Update.pm.pl -> Update module                                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::Update;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use File::Copy;
use Cwd;
use Archive::Tar;
use LWP::Simple;
use strict;

require "ControlPanel/Output/Update.pm.pl";

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

  my $Skin = Skin::CP::Update->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# view subroutine
sub view {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'}, REQUIRE_SUPER => 1);

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #
  
  my @Fields = (
    "SERVER",
    "USERNAME",
    "PASSWORD"
  );

  my @Error;
  foreach my $field (@Fields) {
    if (!$SD::QUERY{'FORM_'.$field}) {
      push(@Error, "MISSING-".$field);
    }
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  my $Result = getstore("http://$SD::QUERY{'FORM_USERNAME'}:$SD::QUERY{'FORM_PASSWORD'}\@$SD::QUERY{'FORM_SERVER'}/sd/updates.list", "$SYSTEM->{'TEMP_PATH'}/updates.list");
  if ($Result eq "401") {
    $self->show(DB => $in{'DB'}, ERROR => "INVALID-LOGIN");
    return 1;
  }	elsif ($Result ne "200") {
    $self->show(DB => $in{'DB'}, ERROR => "CONN-ERROR");
    return 1;
  }

  my (@Versions, $Start);
  
  &Standard::FileOpen(*LIST, "r", "$SYSTEM->{'TEMP_PATH'}/updates.list");
  foreach my $line (<LIST>) {
    my ($version, $file, $description) = split(/::/, $line);
    push(@Versions, { VERSION => $version, FILE => $file, DESCRIPTION => $description }) if ($Start);
    $Start = 1 if ($version eq $SD::VERSION);
  }
  close(LIST);

  unlink("$SYSTEM->{'TEMP_PATH'}/updates.list") || &Error::CGIError("Error removing updates list. $!", "$SYSTEM->{'TEMP_PATH'}/updates.list");

  my %INPUT;
  
  $INPUT{'VERSIONS'} = \@Versions;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::Update->new();

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
  
  if (!$SD::QUERY{'FORM_SERVER'} || !$SD::QUERY{'FORM_USERNAME'} || !$SD::QUERY{'FORM_PASSWORD'}) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  if (!$SD::QUERY{'FORM_VERSION'}) {
    $self->view(DB => $in{'DB'});
    return 1;
  }

  my $Result = getstore("http://$SD::QUERY{'FORM_USERNAME'}:$SD::QUERY{'FORM_PASSWORD'}\@$SD::QUERY{'FORM_SERVER'}/sd/updates.list", "$SYSTEM->{'TEMP_PATH'}/updates.list");
  if ($Result eq "401") {
    $self->show(DB => $in{'DB'}, ERROR => "INVALID-LOGIN");
    return 1;
  }	elsif ($Result ne "200") {
    $self->show(DB => $in{'DB'}, ERROR => "CONN-ERROR");
  }

  my (@Versions, $Start, $End);
  &Standard::FileOpen(*LIST, "r", "$SYSTEM->{'TEMP_PATH'}/updates.list");
  foreach my $line (<LIST>) {
    my ($version, $file, $description) = split(/::/, $line);
    push(@Versions, { VERSION => $version, FILE => $file, DESCRIPTION => $description }) if ($Start);
    $Start = 1 if ($version eq $SD::VERSION);
    $End = 1 and last if ($version eq $SD::QUERY{'FORM_VERSION'});
  }
	close(LIST);

  unlink("$SYSTEM->{'TEMP_PATH'}/updates.list") || &Error::CGIError("Error removing updates list. $!", "$SYSTEM->{'TEMP_PATH'}/updates.list");
	
	unless ($Start && $End) {
	  $self->view(DB => $in{'DB'});
	  return 1;
	}

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my $Skin = Skin::CP::Update->new();

  &Standard::PrintHTMLHeader();  
  print $Skin->do("header");

  $self->Print($self, "", "uplevel");
  $self->Print($self, "Beginning update...\n\n", "element");
  
  mkdir("$SYSTEM->{'TEMP_PATH'}/Update", 0777);
  chmod(0777, "$SYSTEM->{'TEMP_PATH'}/Update");

  my $count = 1;
  foreach my $version (@Versions) {
    $self->Print($self, "Upgrading to $version->{'DESCRIPTION'}...", "element");
    $self->Print($self, "", "uplevel");
    $self->Print($self, "Downloading update package... ", "element");
    my $result = getstore("http://$SD::QUERY{'FORM_USERNAME'}:$SD::QUERY{'FORM_PASSWORD'}\@$SD::QUERY{'FORM_SERVER'}/sd/$version->{'FILE'}", "$SYSTEM->{'TEMP_PATH'}/Update/$version->{'FILE'}");
    if ($result eq "200") {
      $self->Print($self, "Done.", "success");
    } else {
      $self->Print($self, "Error: $result", "error") and exit;
    }

    $self->Print($self, "Checking package... ", "element");
    if ($version->{'FILE'} =~ /\.tar$/ || $version->{'FILE'} =~ /\.pak$/) {
      $self->Print($self, "Seems OK.", "success");
    }	else {
      $self->Print($self, "Error: Package is not valid.", "error") and exit;
    }

    if ($version->{'FILE'} =~ /\.tar$/) {
      $self->Print($self, "Unpacking package... ", "element");
			
      mkdir("$SYSTEM->{'TEMP_PATH'}/Package$count", 0777) || ($self->Print($self, "Error: $!", "error") and exit);
      chmod(0777, "$SYSTEM->{'TEMP_PATH'}/Package$count");
			
      my $tar = Archive::Tar->new();
         $tar->read("$SYSTEM->{'TEMP_PATH'}/Update/".$version->{'FILE'}, 0);
			
      my $cwd = cwd();
      chdir("$SYSTEM->{'TEMP_PATH'}/Package$count");
      my @files = $tar->list_files();
      $tar->extract(@files);
      chdir($cwd);

      $self->Print($self, "Done.", "success");
    } else {
      $self->Print($self, "Copying install.pak... ", "element");
      mkdir("$SYSTEM->{'TEMP_PATH'}/Package$count", 0777) || ($self->Print($self, "Error: $!", "error") and exit);
      chmod(0777, "$SYSTEM->{'TEMP_PATH'}/Package$count");
      copy("$SYSTEM->{'TEMP_PATH'}/Update/$version->{'FILE'}", "$SYSTEM->{'TEMP_PATH'}/Package$count/install.pak") || ($self->Print($self, "Error: $!", "error") and exit);
      $self->Print($self, "Done.", "success");
    }
		
    $self->Print($self, "Executing package...", "element");
    $self->Print($self, "", "uplevel");

    eval {
      require "$SYSTEM->{'TEMP_PATH'}/Package$count/install.pak";
      my $PACK = Package->new();
         $PACK->Install($self, "$SYSTEM->{'TEMP_PATH'}/Package$count");
    };
    if ($@) {
      $self->Print($self, "Error: $@", "error") and exit;
    }
    
    $self->Print($self, "", "downlevel");
		
    $self->Print($self, "Finished executing package. Deleting installation files... ", "element");
    unless (rmtree("$SYSTEM->{'TEMP_PATH'}/Package$count")) {
      $self->Print($self, "Error: $!", "error") and exit;
    }
    unless (unlink("$SYSTEM->{'TEMP_PATH'}/Update/$version->{'FILE'}")) {
      $self->Print($self, "Error: $!", "error") and exit;
    }
    $self->Print($self, "Done.", "success");
    
    $self->Print($self, "", "downlevel");
    $count++;
  }

  $self->Print($self, "Update complete. Deleting installation files... ", "element");
  if (rmtree("$SYSTEM->{'TEMP_PATH'}/Update")) {
    $self->Print($self, "Done.", "success");
  }	else {
    $self->Print($self, "Error: $!", "error");
  }

  $self->Print($self, "\n\n", "");
  $self->Print($self, "All done!", "element");
  $self->Print($self, "", "downlevel");

  print $Skin->do("footer");

  exit;
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