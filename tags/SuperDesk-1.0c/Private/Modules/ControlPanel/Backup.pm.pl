###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/Backup.pm.pl -> Backup module                                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::Backup;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use File::Path;
use File::Copy;
use File::Find;
use Cwd;
use Archive::Tar;
use strict;

require "ControlPanel/Output/Backup.pm.pl";

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
  # Printing page...                                                     #

  my $Skin = Skin::CP::Backup->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show();
  
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
  # Preparing data...                                                    #

  my $Skin = Skin::CP::Backup->new();

  my $Epoch = time;
  my $BackupDir = $SYSTEM->{'BACKUP_PATH'}."/SD-".$Epoch;

  &Standard::PrintHTMLHeader();  
  print $Skin->do("header");

  my $Exit = eval {
    sub {
      close(LOG);

      print $Skin->do("footer");
      exit;
    }
  };
  
  &Standard::FileOpen(*LOG, "w", $BackupDir.".log");

  $self->Print($self, "", "uplevel");
  $self->Print($self, "Beginning backup of SuperLinks.\n\n", "element");
  
  $self->Print($self, "Creating directory for Backup ($BackupDir)... ", "element");
  mkdir($BackupDir, 0777) || ($self->Print($self, "Error: $!", "error") and &$Exit);
  chmod(0777, $BackupDir);
  $self->Print($self, "Done.", "success");

  opendir(DIR, "$SYSTEM->{'DB_PATH'}");
  my @Tables;
  foreach my $file (grep(/\.cfg$/, readdir(DIR))) {
    $file =~ m/^(.*)\.cfg$/;
    push(@Tables, $1);
  }
  closedir(DIR);

  foreach my $table (@Tables) {
    $self->Print($self, "Backing-up \"".$table."\" table...", "element");
    $self->Print($self, "", "uplevel");
    if (
      $self->myBackupTable(
        $Skin,
        DB      => $in{'DB'},
        TO      => $BackupDir,
        TABLE   => $table
      )
    ) {
      $self->Print($self, "", "downlevel");
    } else {
      &$Exit;
    }
  }

  if ($SD::QUERY{'FORM_BACKUP_SKINS'}) {
    $self->Print($self, "Backing-up skins... ", "element");
    
    mkdir("$BackupDir/Skins") || ($self->Print($self, "Error: $!", "error") and &$Exit);
    my $cwd = cwd();
  
    my (@files, @directories);
    my $findsub = eval {
      sub {
        if (-f) {
          push(@files, $File::Find::name);
        } elsif (-d && $_ !~ /^\.\.?$/) {
          push(@directories, $File::Find::name);
        }
      }
    };

    chdir("$SD::PATH/Private/Skins");
    find(\&$findsub, ".");
    chdir($cwd);

    foreach my $directory (sort @directories) {
      $directory =~ s/^\.\///;
      mkdir("$BackupDir/Skins/$directory", 0777) || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0777, "$BackupDir/Skins/$directory");
    }
    foreach my $file (@files) {
      $file =~ s/^\.\///;
      copy("$SD::PATH/Private/Skins/$file", "$BackupDir/Skins/$file") || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0666, "$BackupDir/Skins/$file");
    }
    
    $self->Print($self, "Done.", "success");
  }

  if ($SD::QUERY{'FORM_BACKUP_ATTACHMENTS'}) {
    $self->Print($self, "Backing-up attachments... ", "element");
    
    mkdir("$BackupDir/Attachments") || ($self->Print($self, "Error: $!", "error") and &$Exit);
    my $cwd = cwd();
  
    my (@files, @directories);
    my $findsub = eval {
      sub {
        if (-f) {
          push(@files, $File::Find::name);
        } elsif (-d && $_ !~ /^\.\.?$/) {
          push(@directories, $File::Find::name);
        }
      }
    };

    chdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments");
    find(\&$findsub, ".");
    chdir($cwd);

    foreach my $directory (sort @directories) {
      $directory =~ s/^\.\///;
      mkdir("$BackupDir/Attachments/$directory", 0777) || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0777, "$BackupDir/Attachments/$directory");
    }
    foreach my $file (@files) {
      $file =~ s/^\.\///;
      copy("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$file", "$BackupDir/Attachments/$file") || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0666, "$BackupDir/Attachments/$file");
    }
    
    $self->Print($self, "Done.", "success");
  }

  if ($SD::QUERY{'FORM_COMPRESS'}) {
    $self->Print($self, "Packing the backup... ", "element");
    my $result = $self->myPack("SD-".$Epoch);
    if ($result == 1) {
      $self->Print($self, "Done.", "success");
      $self->Print($self, "Removing backup directory... ", "element");
      rmtree($BackupDir);
      $self->Print($self, "Done.", "success");
    } else {
      $self->Print($self, "Error: $result", "error");
    }
  }
  
  if ($SD::QUERY{'FORM_DESCRIPTION'}) {
    $self->Print($self, "Writing backup description file... ", "element");
    if (open(DESC, ">$BackupDir.txt")) {
      print DESC $SD::QUERY{'FORM_DESCRIPTION'};
      close(DESC);
      $self->Print($self, "Done.", "success");
    } else {
      $self->Print($self, "Error: $!", "error");
    }
  }

  $self->Print($self, "\n\n", "");
  $self->Print($self, "All done!", "element");
  $self->Print($self, "", "downlevel");

  &$Exit;
}

###############################################################################
# myBackupTable subroutine
sub myBackupTable {
  my $self = shift;
  my $Skin = shift;
  my %in = (DB => undef, TO => "", TABLE => "", @_);

  $self->Print($self, "Creating a backup directory for the table data... ", "element");
  mkdir ("$in{'TO'}/$in{'TABLE'}", 0777) || ($self->Print($self, "Error: $!", "error") and return);
  chmod (0777, "$in{'TO'}/$in{'TABLE'}");
  $self->Print($self, "Done.", "success");

  $self->Print($self, "Exporting the table... ", "element");

  if (my $Export = $in{'DB'}->Export(CFG => "$SYSTEM->{'DB_PATH'}/$in{'TABLE'}.cfg", TABLE => $in{'TABLE'})) {
    open (EXPORT, ">$in{'TO'}/$in{'TABLE'}/$in{'TABLE'}.export") || ($self->Print($self, "Error: $!", "error") and return);
    print EXPORT $Export;
    close(EXPORT);
    $self->Print($self, "Done.", "success");
  }	else {
    $self->Print($self, "Error: $in{'DB'}->{'ERROR'}", "error") and return;
  }

  $self->Print($self, "Copying the table's config file... ", "element");
  copy ("$SYSTEM->{'DB_PATH'}/$in{'TABLE'}.cfg", "$in{'TO'}/$in{'TABLE'}.cfg") || ($self->Print($self, "Error: $!", "error") and return);
  $self->Print($self, "Done.", "success");

  return 1;
}

###############################################################################
# myPack subroutine
sub myPack {
  my $self = shift;
  my ($Backup) = @_;

  my $Cwd = cwd();
  chdir($SYSTEM->{'BACKUP_PATH'});

  my @Files = $self->myExplore($SYSTEM->{'BACKUP_PATH'}, $Backup);

  my $Tar = Archive::Tar->new();
     $Tar->add_files(@Files) || (chdir($Cwd) and return $Archive::Tar::error);

  if ($Archive::Tar::compression) {
    $Tar->write("$Backup.tar.gz", 1);
  } else {
    $Tar->write("$Backup.tar");
  }

  chdir($Cwd);

  return 1;
}

###############################################################################
# myExplore subroutine
sub myExplore {
  my $self = shift;
  my ($Base, $Directory) = @_;

  my @Return;

  opendir(DIR, $Base."/".$Directory);
  my @List = readdir(DIR);
  closedir(DIR);

  foreach my $file (@List) {
    next if ($file =~ /^\.\.?$/);
    
    if (-d $Base."/".$Directory."/".$file) {
      push(@Return, $self->myExplore($Base, $Directory."/".$file));
    } else {
      push(@Return, $Directory."/".$file);
    }
  }
  
  return @Return;
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

  print LOG $message;

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