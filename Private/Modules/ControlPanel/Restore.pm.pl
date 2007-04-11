###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/Restore.pm.pl -> Restore module                                #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::Restore;

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

require "ControlPanel/Output/Restore.pm.pl";

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

  my @Backups;
  opendir(DIR, $SYSTEM->{'BACKUP_PATH'}) || &Error::CGIError("Error opening backup directory. $!", $SYSTEM->{'BACKUP_PATH'});
  foreach my $file (grep(/\.log$/, readdir(DIR))) {
    $file =~ m/^SD-(.*)\.log$/;
    
    my $epoch = $1;
    my $date = &Standard::ConvertEpochToDate($epoch);
    my $time = &Standard::ConvertEpochToTime($epoch);
    
    my $description;
    if (-e "$SYSTEM->{'BACKUP_PATH'}/SD-$epoch.txt") {
      open(DESC, "$SYSTEM->{'BACKUP_PATH'}/SD-$epoch.txt") || &Error::CGIError("Error opening backup description file. $!", "$SYSTEM->{'BACKUP_PATH'}/SD-$epoch.txt");
      $description = join("", <DESC>);
      close(DESC);
    }
    
    push(@Backups, { SECOND => $epoch, TIME => $time, DATE => $date, DESCRIPTION => $description });
  }

  my %INPUT;
  
  $INPUT{'BACKUPS'} = \@Backups;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::Restore->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
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

  if (!$SD::QUERY{'FORM_BACKUP'} || !(-e "$SYSTEM->{'BACKUP_PATH'}/$SD::QUERY{'FORM_BACKUP'}.log")) {
    $self->show(DB => $in{'DB'});
    return 1;
  }

  #----------------------------------------------------------------------#
  # Preparing data...                                                    #

  my $Skin = Skin::CP::Restore->new();

  &Standard::PrintHTMLHeader();  
  print $Skin->do("header");

  my $Exit = eval {
    sub {
      print $Skin->do("footer");
      exit;
    }
  };

  my $Backup           = $SD::QUERY{'FORM_BACKUP'};
  my $BackupDirectory  = $SYSTEM->{'BACKUP_PATH'};
     $BackupDirectory  =~ s/\\/\//g;
     $BackupDirectory  =~ s/\/$//g;
  my $RestoreDirectory = $SYSTEM->{'DB_PATH'};

  my $Cwd = cwd();
  my $Tar = Archive::Tar->new();

  $self->Print($self, "", "uplevel");
  $self->Print($self, "Beginning backup of SuperLinks.\n\n", "element");

  if (-e "$BackupDirectory/$Backup.tar.gz") {
    $self->Print($self, "Unpacking $Backup.tar.gz archive... ", "element");

    $Tar->read("$BackupDirectory/$Backup.tar.gz", 1);

    chdir($BackupDirectory);
    my @files = $Tar->list_files();
    $Tar->extract(@files);
    chdir($Cwd);

    $self->Print($self, "Done.", "success");
  } elsif (-e "$BackupDirectory/$Backup.tar") {
    $self->Print($self, "Unpacking $Backup.tar archive... ", "element");

    $Tar->read("$BackupDirectory/$Backup.tar");

    chdir($BackupDirectory);
    my @files = $Tar->list_files();
    $Tar->extract(@files);
    chdir($Cwd);

    $self->Print($self, "Done.", "success");
  }

  $self->Print($self, "Checking \"$BackupDirectory/$Backup\"... ", "element");
  if (-e "$BackupDirectory/$Backup" && $BackupDirectory && $Backup) {
    $self->Print($self, "Found.", "success");
  } else {
    $self->Print($self, "Error: Directory not found", "error") and &$Exit;
  }

  opendir(DIR, "$BackupDirectory/$Backup");
  my @Tables;
  foreach my $file (grep(/\.cfg$/, readdir(DIR))) {
    $file =~ m/^(.*)\.cfg$/;
    push(@Tables, $1);
  }
  closedir(DIR);

  foreach my $table (@Tables) {
    $self->Print($self, "Restoring \"$table\" table...", "element");
    $self->Print($self, "", "uplevel");
    $self->Print($self, "Dropping current table... ", "element");
    $in{'DB'}->DropTable(TABLE => $table) || ($self->Print($self, "Error: $in{'DB'}->{'ERROR'}", "error") and &$Exit);
    $self->Print($self, "Done.", "success");
    $self->Print($self, "Copying \"$table.cfg\"... ", "element");
    copy("$BackupDirectory/$Backup/$table.cfg", "$RestoreDirectory/$table.cfg") || ($self->Print($self, "Error: $!", "error") and &$Exit);
    $self->Print($self, "Done.", "success");
    
    $self->Print($self, "Importing from the restore file... ", "element");
    open(EXPORT, "$BackupDirectory/$Backup/$table/$table.export") || ($self->Print($self, "Error: $!", "error") and &$Exit);
    my @EXPORT = <EXPORT>;
    close(EXPORT);
    chomp(@EXPORT);
   
    $in{'DB'}->Import(
      CFG     => "$RestoreDirectory/$table.cfg",
      TABLE   => $table,
      CONTENT => \@EXPORT
    ) || ($self->Print($self, "Error: $in{'DB'}->{'ERROR'}", "error") and &$Exit);
    $self->Print($self, "Done.", "success");
    
    $self->Print($self, "", "downlevel");
  }

  if (-e "$BackupDirectory/$Backup/Skins" && $SD::QUERY{'FORM_RESTORE_SKINS'}) {
    $self->Print($self, "Restoring skins...", "element");
    $self->Print($self, "", "uplevel");
    
    $self->Print($self, "Removing current skins... ", "element");
    rmtree("$SD::PATH/Private/Skins") || ($self->Print($self, "Error: $!", "error") and &$Exit);
    $self->Print($self, "Done.", "success");
    
    $self->Print($self, "Restoring backed-up skins... ", "element");
    
    mkdir("$SD::PATH/Private/Skins") || ($self->Print($self, "Error: $!", "error") and &$Exit);
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

    chdir("$BackupDirectory/$Backup/Skins");
    find(\&$findsub, ".");
    chdir($cwd);

    foreach my $directory (sort @directories) {
      $directory =~ s/^\.\///;
      mkdir("$SD::PATH/Private/Skins/$directory", 0777) || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0777, "$SD::PATH/Private/Skins/$directory");
    }
    foreach my $file (@files) {
      $file =~ s/^\.\///;
      copy("$BackupDirectory/$Backup/Skins/$file", "$SD::PATH/Private/Skins/$file") || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0666, "$SD::PATH/Private/Skins/$file");
    }
    
    $self->Print($self, "Done.", "success");

    $self->Print($self, "", "downlevel");
  }

  if (-e "$BackupDirectory/$Backup/Attachments" && $SD::QUERY{'FORM_RESTORE_ATTACHMENTS'}) {
    $self->Print($self, "Restoring attachments...", "element");
    $self->Print($self, "", "uplevel");
    
    $self->Print($self, "Removing current attachments... ", "element");
    rmtree("$SYSTEM->{'PUBLIC_PATH'}/Attachments") || ($self->Print($self, "Error: $!", "error") and &$Exit);
    $self->Print($self, "Done.", "success");
    
    $self->Print($self, "Restoring backed-up attachments... ", "element");
    
    mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments") || ($self->Print($self, "Error: $!", "error") and &$Exit);
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

    chdir("$BackupDirectory/$Backup/Attachments");
    find(\&$findsub, ".");
    chdir($cwd);

    foreach my $directory (sort @directories) {
      $directory =~ s/^\.\///;
      mkdir("$SYSTEM->{'PUBLIC_PATH'}/Attachments/$directory", 0777) || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0777, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$directory");
    }
    foreach my $file (@files) {
      $file =~ s/^\.\///;
      copy("$BackupDirectory/$Backup/Attachments/$file", "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$file") || ($self->Print($self, "Error: $!", "error") and &$Exit);
      chmod(0666, "$SYSTEM->{'PUBLIC_PATH'}/Attachments/$file");
    }
    
    $self->Print($self, "Done.", "success");

    $self->Print($self, "", "downlevel");
  }

  if (-e "$SYSTEM->{'BACKUP_PATH'}/$Backup.tar.gz" || -e "$SYSTEM->{'BACKUP_PATH'}/$Backup.tar") {
    $self->Print($self, "Removing backup directory... ", "element");
    if (rmtree("$BackupDirectory/$Backup")) {
      $self->Print($self, "Done.", "success");
    } else {
      $self->Print($self, "Error removing directory. $!. Please remove it manually.", "check");
    }
  }

  $self->Print($self, "\n\n", "");
  $self->Print($self, "All done!", "element");
  $self->Print($self, "", "downlevel");
  
  &$Exit;
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