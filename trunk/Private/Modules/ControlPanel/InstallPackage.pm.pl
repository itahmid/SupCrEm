###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/InstallPackage.pm.pl -> InstallPackage module                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::InstallPackage;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use File::Copy;
use Cwd;
use Archive::Tar;
use strict;

require "ControlPanel/Output/InstallPackage.pm.pl";

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

  my $Skin = Skin::CP::InstallPackage->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(error => $in{'ERROR'});
  
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

  my $Package = $SD::CGI->param('FORM_PACKAGE');

  unless ($Package) {
    $self->show(DB => $in{'DB'}, ERROR => "MISSING-PACKAGE");
    return 1;
  }

  my $tmpPackage = $SD::CGI->tmpFileName($Package);
  unless (-e $tmpPackage) {
    $self->show(DB => $in{'DB'});
    return 1;
  }
  if ($Package !~ /\.tar$/ && $Package !~ /\.pak$/) {
    $self->show(DB => $in{'DB'}, ERROR => "INVALID-PACKAGE");
    return 1;
  }
  
  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my $Skin = Skin::CP::InstallPackage->new();

  &Standard::PrintHTMLHeader();  
  print $Skin->do("header");

  $self->Print($self, "", "uplevel");
  $self->Print($self, "Starting installation of package...\n\n", "element");
  
  if ($Package =~ /\.tar$/) {
    $self->Print($self, "Creating directory for package... ", "element");
    rmtree("$SYSTEM->{'TEMP_PATH'}/Package");
    mkdir("$SYSTEM->{'TEMP_PATH'}/Package", 0777) || ($self->Print($self, "Error: $!", "error") and exit);
    chmod(0777, "$SYSTEM->{'TEMP_PATH'}/Package");
    $self->Print($self, "Done.", "success");

    $self->Print($self, "Unpacking package...", "element");
    my $tar = Archive::Tar->new();
       $tar->read($tmpPackage, 0);
         
    my $cwd = cwd();
    chdir("$SYSTEM->{'TEMP_PATH'}/Package");
    my @files = $tar->list_files();
    $tar->extract(@files);
    chdir($cwd);
      
    $self->Print($self, "Done.", "success");
  } elsif ($Package =~ /\.pak$/) {
    $self->Print($self, "Creating directory for package... ", "element");
    rmtree("$SYSTEM->{'TEMP_PATH'}/Package");
    mkdir("$SYSTEM->{'TEMP_PATH'}/Package", 0777) || ($self->Print($self, "Error: $!", "error") and exit);
    chmod(0777, "$SYSTEM->{'TEMP_PATH'}/Package");
    $self->Print($self, "Done.", "success");

    $self->Print($self, "Copying package to directory... ", "element");
    copy($tmpPackage, "$SYSTEM->{'TEMP_PATH'}/Package/install.pak") || ($self->Print($self, "Error: $!", "error") and exit);
    $self->Print($self, "Done.", "success");
  }

  $self->Print($self, "Getting package details...", "element");
  $self->Print($self, "", "uplevel");
	
  require "$SYSTEM->{'TEMP_PATH'}/Package/install.pak";
  my $PACK = Package->new();
	
  $self->Print($self, "Package Name: $PACK->{'PACKAGE_NAME'}", "element");
  $self->Print($self, "Package Author: $PACK->{'PACKAGE_AUTHOR'}", "element");
  $self->Print($self, "Package Details: $PACK->{'PACKAGE_DETAILS'}", "element") if ($PACK->{'PACKAGE_DETAILS'});
  $self->Print($self, "", "downlevel");
	
  $self->Print($self, "Executing package...", "element");
  $self->Print($self, "", "uplevel");
  $PACK->Install($self, "$SYSTEM->{'TEMP_PATH'}/Package");
  $self->Print($self, "", "downlevel");
	
  $self->Print($self, "Finished executing package. Deleting installation files... ", "element");
  if (rmtree("$SYSTEM->{'TEMP_PATH'}/Package")) {
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