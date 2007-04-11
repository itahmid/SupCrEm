###############################################################################
# UltraBoard 2000 Database Engine (DBM)                                       #
# Copyright (c) 1999-2000 UltraScripts.com, Inc. All Rights Reserved.         #
# UltraBoard is available from http://www.ub2k.com/ or                        #
# http://www.ultrascripts.com/                                                #
# Licenced to Gregory Nolle & PlasmaPulse Solutions for use in SuperDesk.     #
###############################################################################
package Database;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
require "Error.pm.pl";
require "Standard.pm.pl";

use Fcntl;
use AnyDBM_File;
use File::Path;
use strict;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless ($self, $class);
}

sub DESTROY {}

###############################################################################
# Connect function
# - function of connect to database
sub Connect {
  # no need to use this function....
}

###############################################################################
# Disconnect function
# - function of disconnect from database
sub Disconnect {
  # no need to use this function....
}

###############################################################################
# CreateTable function
# - function of creating new table into database
sub CreateTable {
  my $self = shift;
  my %in = (
    "TABLE"       => "",
    "VALUE"       => {},
    "PRIMARY_KEY" => "",
    @_
  );

  my $Table = $in{'TABLE'};

  unless (mkdir ("$SYSTEM->{'DB_PATH'}/$Table", 0777)) {
    $self->{'ERROR'} = "Can't create a new table directory ($SYSTEM->{'DB_PATH'}/$Table). $!";
    return;
  }
  chmod (0777, "$SYSTEM->{'DB_PATH'}/$Table");

  &Standard::lock("file.lock");

  &Standard::FileOpen(*TABLE, "w", "$SYSTEM->{'DB_PATH'}/".$Table.".cfg");
    print TABLE <<TEXT;
package DB;

BEGIN { require "System.pm.pl";  import System  qw(\$SYSTEM ); }

\$DB::Path{'$Table'} = "\$SYSTEM->{'DB_PATH'}/$Table";

%{ \$DB::Table{'$Table'} } = (
TEXT
    my @Keys = sort { $in{'VALUE'}->{$a}[0] <=> $in{'VALUE'}->{$b}[0] } keys %{ $in{'VALUE'} };
    for (my $i = 0; $i <= $#Keys; $i++) {
      my $Key = $Keys[$i];
      my $Space;

      $Space = " " x ( 20 - length ($Key) );
      print TABLE "  ".$Key.$Space."=> [";

      $Space = " " x (2 - length ( $in{'VALUE'}->{$Key}[0] ) );
      print TABLE $Space.$in{'VALUE'}->{$Key}[0].", ";

      $Space = " " x (10 - length ( $in{'VALUE'}->{$Key}[1] ) );
      print TABLE $Space."\"".$in{'VALUE'}->{$Key}[1]."\", ";

      $Space = " " x (5 - length ( $in{'VALUE'}->{$Key}[2] ) );
      print TABLE $Space.$in{'VALUE'}->{$Key}[2].", ";

      $Space = "";
      print TABLE $Space.$in{'VALUE'}->{$Key}[3].", ";

      $Space = " " x (10 - length ( $in{'VALUE'}->{$Key}[4] ) );
      print TABLE $Space."\"".$in{'VALUE'}->{$Key}[4]."\"]";

      print TABLE "," unless $i == $#Keys;
      print TABLE "\n";
    }
    print TABLE <<TEXT;
);

\$DB::PrimaryKey{'$Table'} = "$in{'PRIMARY_KEY'}";

\$DB::Pointer{'$Table'}   = "";

foreach my \$Key ( sort { \$DB::Table{'$Table'}->{\$a}[0] <=> \$DB::Table{'$Table'}->{\$b}[0] } keys \%{ \$DB::Table{'$Table'} } ) {
  push ( \@{ \$DB::Columns{'$Table'} }, \$Key );
  if (\$Key eq \$DB::PrimaryKey{'$Table'}) {
    \$DB::Primary{'$Table'} = \$DB::Table{'$Table'}->{\$Key}[0];
  }
  if (\$DB::Table{'$Table'}->{\$Key}[1] eq "text") {
    \$DB::TextArea{'$Table'}->{\$Key} = \$#{\$DB::Columns{'$Table'}};
  }
}

1;
TEXT
  close (TABLE);
  chmod(0666, "$SYSTEM->{'DB_PATH'}/".$Table.".cfg");

  tie (my %DB, $AnyDBM_File::ISA[0], $SYSTEM->{'DB_PATH'}."/".$Table."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || &Error::CGIError("Can't open file for writing. $!", $SYSTEM->{'DB_PATH'}."/".$Table."/$Table.db.cgi");
  untie (%DB);
  chmod(0666, $SYSTEM->{'DB_PATH'}."/".$Table."/$Table.db.cgi");

  &Standard::FileOpen(*TABLE, "w", $SYSTEM->{'DB_PATH'}."/".$Table."/".$Table.".counter");
    print TABLE "0";
  close (TABLE);
  chmod(0666, $SYSTEM->{'DB_PATH'}."/".$Table."/".$Table.".counter");

  &Standard::lock("file.lock");

  return 1;
}

###############################################################################
# DropTables function
# - function of removing mult-tables at once from database
sub DropTables {
  my $self = shift;
  my %in = ("TABLES" => undef, @_);

  if ((ref ($in{'TABLES'}) eq "") and ($in{'TABLES'} eq "*")) {
    opendir (DB, $SYSTEM->{'DB_PATH'});
      my @files = readdir(DB);
    closedir(DB);

    foreach my $file (@files) {
      unless (-d $SYSTEM->{'DB_PATH'}."/".$file) {
        if ($file =~ /^(.+)\.cfg$/i) {
          $self->DropTable(TABLE => $1) || return;
        }
      }
    }
  } else {
    foreach my $table (@{$in{'TABLES'}}) {
      $self->DropTable(TABLE => $table) || return;
    }
  }

  return 1;
}

###############################################################################
# DropTable function
# - function of removing a table into database
sub DropTable {
  my $self = shift;
  my %in = ("TABLE" => "", @_);

  my $Table = $in{'TABLE'};

  unlink ("$SYSTEM->{'DB_PATH'}/$Table.cfg");
  rmtree ("$SYSTEM->{'DB_PATH'}/$Table");

	return 1;
}

###############################################################################
# Insert function
# - function of insert record into database table
sub Insert {
  my $self = shift;
  my %in = (
    "TABLE"  => "",
    "SKIP "  =>  0,
    "VALUES" => {},
    @_
  );

  my $Table = $in{'TABLE'}; # set current table

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";
  &Standard::lock    ("$Table.lock");

  my $DBTable     = $DB::Table{ $Table };
  my $PrimaryKey  = $DB::PrimaryKey{ $Table };
  my $TextArea    = $DB::TextArea{ $Table };

  &Standard::FileOpen(*DB, "rw", $DB::Path{ $Table }."/$Table.counter");
    my $Counter   = <DB>;
  close (DB);
  chomp ( $Counter );

  $Counter++;

  # checking the primary key of the table is it auto increase number
  if ( ($DBTable->{ $PrimaryKey }[1] eq "autonumber") && ($in{'SKIP'} == 0) ) {
     $in{'VALUES'}->{ $PrimaryKey } = $Counter;
  }

  # validate all data field is it currently
  return unless ( $self->myValidate( $Table, $in{'VALUES'} ) );

  # append data into data file
  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || &Error::CGIError("Can't open file for writing. $!"  , $DB::Path{ $Table }."/$Table.db.cgi");
    if ( $DB{ $in{'VALUES'}->{ $PrimaryKey } } ) {
      if ( ($DBTable->{ $PrimaryKey }[1] eq "autonumber") && ($in{'SKIP'} == 0) ) {
        my @PK = sort {$b <=> $a} keys %DB;

        if ( $DB{ $in{'VALUES'}->{ $PK[0] + 5 } } ) {
          $self->{'ERROR'} = "The primary key \"".$in{'VALUES'}->{ $PrimaryKey }."\" is existed in table \"$Table\". (1)";
          return;
        } else {
          $Counter = $PK[0] + 5 if ( ($PK[0] + 5) > $Counter);
        }
      } else {
        $self->{'ERROR'} = "The primary key \"".$in{'VALUES'}->{ $PrimaryKey }."\" is existed in table \"$Table\".";
        return;
      }
    }

    # process all huge text data # 2.2
    my %OriginalValues;
    foreach my $Key (keys %{$TextArea}) {
      &Standard::FileOpen(*DB, "w", $DB::Path{ $Table }."/".$in{'VALUES'}->{ $PrimaryKey }.".$Key.txt.cgi");
        print DB $in{'VALUES'}->{ $Key };
      close (DB);
      chmod(0666, $DB::Path{ $Table }."/".$in{'VALUES'}->{ $PrimaryKey }.".$Key.txt.cgi");
      $OriginalValues{ $Key } = $in{'VALUES'}->{ $Key };
      $in{'VALUES'}->{ $Key } = $in{'VALUES'}->{ $PrimaryKey }.".$Key.txt";
    }

    $DB{ $in{'VALUES'}->{ $PrimaryKey } } = $self->myEncodeData( $Table, $in{'VALUES'} );
    
    foreach my $Key (keys %OriginalValues) {
      $in{'VALUES'}->{ $Key } = $OriginalValues{ $Key };
    }
  untie (%DB);

  # write data into counter file
  &Standard::FileOpen(*DB, "w", $DB::Path{ $Table }."/$Table.counter");
    print DB $Counter;
  close (DB);

  &Standard::unLock("$Table.lock");

  return $in{'VALUES'}->{ $PrimaryKey };
}

###############################################################################
# Update function
# - function of updating record from database table
sub Update {
  my $self = shift;
  my %in = (
    "TABLE"  => "",
    "VALUES" => {},
    "KEY"    => "",
    "RESET"  =>  0,
    @_
  );

  my $Table = $in{'TABLE'}; # set current table

  if ($in{'KEY'} eq "") {
    $self->{'ERROR'} = "No primary key in table '$Table'.";
    return;
  }

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";
  &Standard::lock    ("$Table.lock");

  my $DBTable     = $DB::Table{ $Table };
  my $PrimaryKey  = $DB::PrimaryKey{ $Table };
  my $TextArea    = $DB::TextArea{ $Table };
  my $Hash        = {};

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || &Error::CGIError("Can't open file for reading. $!", $DB::Path{ $Table }."/$Table.db.cgi");

  unless ( $DB{ $in{'KEY'} } ) {
    $self->{'ERROR'} = "The primary key is not found in table '$Table'.";
    return;
  }

  if ($in{'RESET'} == 0) {
    $Hash = $self->myDecodeData( $Table, $DB{ $in{'KEY'} } );

    foreach my $Key ( keys %{ $in{'VALUES'} } ) {
      next if ($Key eq $PrimaryKey);
      next if (($DB::Table{ $Table }->{$Key}[3] == 1) && ($in{'VALUES'}->{$Key} eq ""));

      # process all huge text data # 2.2
      if ($TextArea->{$Key} ne "") {
        &Standard::FileOpen(*TEXT, "rw", $DB::Path{ $Table }."/".$Hash->{$PrimaryKey}.".$Key.txt.cgi");
          $Hash->{$Key} = join("", <TEXT>);
        close (TEXT);
      }

      if ($in{'VALUES'}->{$Key} =~ /(.*)\$\{(.+)\}(.*)/) {
        $in{'VALUES'}->{$Key} =~ s/\$\{([\.\w]+)\}/\$Hash->{\'$1\'}/ig;
        my $eval = qq~
          sub EvalData {
            my (\$Hash) = \@_;
            return ($in{'VALUES'}->{$Key});
          }
        ~;
        eval "$eval";
        $in{'VALUES'}->{$Key} = &EvalData($Hash);
      }
      $Hash->{$Key} = $in{'VALUES'}->{$Key};
    }
  } else {
    $Hash = $in{'VALUES'};
  }

  # process all huge text data # 2.2
  foreach my $Key (keys %{$TextArea}) {
    if ($Hash->{$Key} ne $Hash->{$PrimaryKey}.".$Key.txt.cgi") {
      &Standard::FileOpen(*DB, "w", $DB::Path{ $Table }."/".$Hash->{$PrimaryKey}.".$Key.txt.cgi");
        print DB $Hash->{$Key};
      close (DB);
      $Hash->{ $Key } = $Hash->{$PrimaryKey}.".$Key.txt.cgi";
    }
  }

  # validate all data field is it currently
  return unless ( $self->myValidate( $Table, $Hash, 1 ) );

  $DB{ $in{'KEY'} } = $self->myEncodeData( $Table, $Hash );

  untie (%DB);

  &Standard::unLock("$Table.lock");

  return $Hash;
}

###############################################################################
# Delete function
# - function of deleting record from database table
sub Delete {
  my $self = shift;
  my %in = (
    "TABLE" => "",
    "KEYS"  => [],
    @_
  );

  my $Table = $in{'TABLE'}; # set current table

  if ($#{ $in{'KEYS'} } < 0) {
    $self->{'ERROR'} = "No primary key for seaching in table '$Table'.";
    return;
  }

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";
  &Standard::lock    ("$Table.lock");

  my $DBTable     = $DB::Table{ $Table };
  my $PrimaryKey  = $DB::PrimaryKey{ $Table };
  my $TextArea    = $DB::TextArea{ $Table };

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || &Error::CGIError("Can't open file for reading. $!", $DB::Path{ $Table }."/$Table.db.cgi");

  for (my $i = 0; $i <= $#{ $in{'KEYS'} }; $i++) {
    unless ( $DB{ $in{'KEYS'}->[$i] } ) {
      next;
    }

    delete ( $DB{ $in{'KEYS'}->[$i] } );

     # process all huge text data # 2.2
    foreach my $Key (keys %{$TextArea}) {
      unlink($DB::Path{ $Table }."/".$in{'KEYS'}->[$i].".$Key.txt.cgi");
    }
  }

  untie (%DB);

  &Standard::unLock("$Table.lock");

  return 1;
}

###############################################################################
# Query function
# - function of searching records from database table
sub Query {
  my $self = shift;
  my %in = (
    "TABLE"   => "",
    "COLUMNS" => [],
    "WHERE"   => {},
    "MATCH"   => "", # ALL/ANY
    "SORT"    => "",
    "BY"      => "",
    "TO"      => "",
    "COUNT"   =>  0,
    @_
  );

  my $Table = $in{'TABLE'}; # set current table

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";
  &Standard::lock("$Table.lock");

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };
  my $TextArea    = $DB::TextArea   { $Table };

  my (%Sort, @Return);

  my (%REString, %EQString, %NEString, %GTString, %LTString, %EQNumber, %NENumber, %GTNumber, %LTNumber);

  my (@Fields);
  if ( scalar @{ $in{'COLUMNS'} } > 0) {
    @Fields = @{ $in{'COLUMNS'} };
  } else {
    push ( @Fields, @{ $Columns } );
  }

  my %SearchText;
  foreach (@Fields) {
    $SearchText{$_} = 1 if $TextArea->{$_};
  }

  $in{'SORT'} = $PrimaryKey unless ($in{'SORT'});

  my $SearchFlag = 0;
  FOREACH: foreach my $Field (keys %{ $in{'WHERE'} } ) {
    FOR: for (my $i = 0; $i <= $#{ $in{'WHERE'}->{$Field} }; $i++) {
      next FOR if $in{'WHERE'}->{$Field}[$i] =~ /\*$/;
      my $Statement = $in{'WHERE'}->{$Field}[$i];

      if ($Statement =~ /^=~(.+)$/) {
        $SearchText{$Field} = 1 if ($TextArea->{$Field} ne "");
        push (@{ $REString{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      }

      if ($Statement =~ /^>(\d+)$/) {
        push (@{ $GTNumber{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      } elsif ($Statement =~ /^>(.+)$/) {
        push (@{ $GTString{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      }

      if ($Statement =~ /^<(\d+)$/) {
        push (@{ $LTNumber{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      } elsif ($Statement =~ /^<(.+)$/) {
        push (@{ $LTString{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      }

      if ($Statement =~ /^!=(\d+)$/) {
        push (@{ $NENumber{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      } elsif ($Statement =~ /^!=(.+)$/) {
        push (@{ $NEString{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      }

      if ($DB::Table{$Table}->{$Field}->[1] =~ /number$/ && $Statement =~ /^=?(\d+)$/) {
        push (@{ $EQNumber{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      } elsif ($Statement =~ /^=?(.+)$/) {
        push (@{ $EQString{$Field} }, $1);
        $SearchFlag =  1;
        next FOR;
      }
    }
  }

  foreach my $Field (keys %REString) {
    for (my $i = 0; $i <= $#{ $REString{$Field} }; $i++) {
      my $tmp = "$REString{$Field}->[$i]";
      $REString{$Field}->[$i] = eval "sub { m/\Q$tmp\E/io }";
    }
  }

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || &Error::CGIError("Can't open file for reading. $!", $DB::Path{ $Table }."/$Table.db.cgi");

  my $MatchAll  = 1 if ($in{'MATCH'} eq "ALL");
  my $FoundHits = 0;

  LINE: foreach my $Line ( values %DB ) {
    my $Matched = 0;
    my $Data    = $self->myDecodeData($Table, $Line);

    if ($SearchFlag == 0) {
      $Matched = 1;
      goto FOUND;
    }

    # process all huge text data # 2.2
    foreach my $Key (keys %SearchText) {
      &Standard::FileOpen(*TEXT, "rw", $DB::Path{ $Table }."/".$Data->{$PrimaryKey}.".$Key.txt.cgi");
        $Data->{$Key} = join("", <TEXT>);
      close (TEXT);
    }

    # searching fields equal to the regular expression
    foreach my $Field (keys %REString) {
      foreach my $Value ( @{ $REString{$Field} } ) {
        $_ = $Data->{ $Field };
        if (&{$Value}) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields equal to numbers
    foreach my $Field (keys %EQNumber) {
      foreach my $Value ( @{ $EQNumber{$Field} } ) {
        if ($Data->{ $Field } == $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields equal to strings
    foreach my $Field (keys %EQString) {
      foreach my $Value ( @{ $EQString{$Field} } ) {
        if ($Data->{ $Field } eq $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields not equal to numbers
    foreach my $Field (keys %NENumber) {
      foreach my $Value ( @{ $NENumber{$Field} } ) {
        if ($Data->{ $Field } != $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields not equal to strings
    foreach my $Field (keys %NEString) {
      foreach my $Value ( @{ $NEString{$Field} } ) {
        if ($Data->{ $Field } ne $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields greater then numbers
    foreach my $Field (keys %GTNumber) {
      foreach my $Value ( @{ $GTNumber{$Field} } ) {
        if ($Data->{ $Field } > $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields greater then strings
    foreach my $Field (keys %GTString) {
      foreach my $Value ( @{ $GTString{$Field} } ) {
        if ($Data->{ $Field } gt $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields less then numbers
    foreach my $Field (keys %LTNumber) {
      foreach my $Value ( @{ $LTNumber{$Field} } ) {
        if ($Data->{ $Field } < $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    # searching fields greater then strings
    foreach my $Field (keys %LTString) {
      foreach my $Value ( @{ $LTString{$Field} } ) {
        if ($Data->{ $Field } lt $Value) {
          $Matched = 1;
          goto FOUND unless $MatchAll;
        } else {
          next LINE if $MatchAll;
        }
      }
    }

    FOUND: # check is it matched
    if ($Matched == 1) {
      my %tmp;
      foreach (@Fields) {
        $tmp{$_} = $Data->{$_};
      }
      push (@Return, \%tmp);
      $Sort{$#Return} = $tmp{ $in{'SORT'} };
      $FoundHits++;
    }
  }

  untie (%DB);

  return $FoundHits if ($in{'COUNT'});

  # sort the list of return
  my @tmp;
  if ($DBTable->{$in{'SORT'}}[1] eq "string") {
    if ($in{'BY'} eq "Z-A") {
      foreach my $i (sort { $Sort{$b} cmp $Sort{$a} } keys %Sort) {
        push (@tmp, $Return[$i]);
      }
    } else {
      foreach my $i (sort { $Sort{$a} cmp $Sort{$b} } keys %Sort) {
        push (@tmp, $Return[$i]);
      }
    }
  } else {
    if ($in{'BY'} eq "Z-A") {
      foreach my $i (sort { $Sort{$b} <=> $Sort{$a} } keys %Sort) {
        push (@tmp, $Return[$i]);
      }
    } else {
      foreach my $i (sort { $Sort{$a} <=> $Sort{$b} } keys %Sort) {
        push (@tmp, $Return[$i]);
      }
    }
  }

  @Return = @tmp;
  @tmp    = ();

  if ($in{'TO'}) {
    my ($From, $To) = split (/-/, $in{'TO'});

    $From = 0        if (($From eq "") || ($From < 0       ));
    $To   = $#Return if (($To   eq "") || ($To   > $#Return));

    @Return = @Return[$From..$To];
  }

  my %Index;
  for (my $i = 0; $i <= $#Return; $i++) {
    $Index{ $Return[$i]{ $PrimaryKey } } = $i;
  }

  &Standard::unLock("$Table.lock");

  return (\@Return, \%Index);
}

###############################################################################
# BinarySelect function
# - function of searching records from database table by using binary search
sub BinarySelect {
  my $self = shift;
  my %in = (
    "TABLE"   => "",
    "COLUMNS" => [],
    "KEY"     => "",
    @_
  );

  my $Table = $in{'TABLE'}; # set current table

  if ($in{'KEY'} eq "") {
    $self->{'ERROR'} = "No primary key for seaching in table '$Table'.";
    return;
  }

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";
  &Standard::lock    ("$Table.lock");

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };
  my $TextArea    = $DB::TextArea{ $Table };

  my (@Fields);
  if ( scalar @{ $in{'COLUMNS'} } > 0) {
    @Fields = @{ $in{'COLUMNS'} };
  } else {
    push ( @Fields, @{ $Columns } );
  }

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || &Error::CGIError("Can't open file for reading. $!", $DB::Path{ $Table }."/$Table.db.cgi");

  unless ( $DB{ $in{'KEY'} } ) {
    $self->{'ERROR'} = "Data is not found in table \"$Table\".";
    return;
  }

  my $Data = $self->myDecodeData($Table, $DB{ $in{'KEY'} });

  untie (%DB);

  my %Return;
  foreach my $Field (@Fields) {
    # process all huge text data # 2.2
    if ($TextArea->{$Field} ne "") {
      &Standard::FileOpen(*TEXT, "rw", $DB::Path{ $Table }."/".$Data->{$PrimaryKey}.".$Field.txt.cgi");
        $Data->{$Field} = join("", <TEXT>);
      close (TEXT);
    }
    $Return{$Field} = $Data->{$Field};
  }

  &Standard::unLock("$Table.lock");

  return \%Return;
}

###############################################################################
# myEncodeData function (Private)
# - function of encoding the data from input, and parse it into a line
sub myEncodeData {
  my $self = shift;
  my ($Table, $Value) = @_;

  my $Return;
  my $Columns = $DB::Columns { $Table };

  my $Delimeter   = "|^|";
  my $unDelimeter = "|&|";

  foreach my $Column ( @{ $Columns } ) {
    my $tmp =  $Value->{$Column};


#    $tmp    =~ s/^\s+//g;
#    $tmp    =~ s/\s+$//g;

    $tmp    =~ s/\n/\\n/g;
    $tmp    =~ s/\r//g;

    $tmp    =~ s/\Q$Delimeter\E/$unDelimeter/g;

    $Return .= $tmp.$Delimeter;
  }

  $Return =~ s/\Q$Delimeter\E$//g;

  return $Return;
}

###############################################################################
# myDecodeData function (Private)
# - function of decoding the data from line, and parse it into a array
sub myDecodeData {
  my $self = shift;
  my ($Table, $Data) = @_;
  my (@tmp, %Return);

  my $Columns = $DB::Columns { $Table };

  my $Delimeter   = "|^|";
  my $unDelimeter = "|&|";

  chomp ($Data);
  @tmp = split (/\Q$Delimeter\E/, $Data, scalar ( $Columns ) );

  for (my $i = 0; $i <= $#{ $Columns }; $i++){
    $tmp[$i]  =~ s/\Q$unDelimeter\E/$Delimeter/g;
    $tmp[$i]  =~ s/\\n/\n/g;
    $Return{ $Columns->[$i] } = $tmp[$i];
  }

  return \%Return;
}

###############################################################################
# myValidate function (Private)
sub myValidate {
  my $self = shift;
  my ($Table, $Value, $Update) = @_;

  $Update = 0 unless $Update;

  my $DBTable = $DB::Table { $Table };

  # validate all data field is it currently
  foreach my $Column ( @{ $DB::Columns{$Table} } ) {
    $Value->{ $Column } =~ s/\r//g;

    if ($DBTable->{$Column}[4] ne "") { # parsing the default values
      if ( $Value->{ $Column } eq "" ) {
        $Value->{ $Column } = $DBTable->{$Column}[4];
      }
    }

    if (($DBTable->{$Column}[3] == 1) && ($Update != 1)) { # checking required fields
      if ( $Value->{ $Column } eq "" ) {
        $self->{'ERROR'} = "Missing value for '$Column' field in table \"$Table\".";
        return;
      }
    }

    if ($DBTable->{$Column}[2] > 0) { # checking length of fields
      if (
        ( $Value->{ $Column } eq "" ) &&
        ( length ( $Value->{ $Column } ) > $DBTable->{ $Column }[2] ) &&
        ( $DBTable->{$Column}[2] != -1 )
      ) {
        $self->{'ERROR'} = "The length of \"$Column\" field is too long in table \"$Table\".";
        return;
      }
    }

    if ($DBTable->{$Column}[1] eq "number") { # checking format of fields
      if ( ($Value->{ $Column } !~ /^[\-\d\.]+$/) && ( $Value->{ $Column } ne "" ) ) {
        $self->{'ERROR'} = "The format of \"$Column\" field is wrong in table \"$Table\".";
        return;
      }
    }
  }

  return 1;
}

###############################################################################
# Export function
# - function of export the table from database
sub Export {
  my $self = shift;
  my %in = ("CFG" => "", "TABLE" => "", @_);

  my $Table = $in{'TABLE'}; # set current table

  require $in{'CFG'};
  &Standard::lock("$Table.lock");

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };
  my $TextArea    = $DB::TextArea   { $Table };

  my $Export = join ("|", @{$Columns})."\n";

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || ($self->{'ERROR'} = "Can't open \"$DB::Path{ $Table }/$Table.db.cgi\" database. $!" and return);
    foreach my $KEY ( sort { $a cmp $b } keys %DB ) {
      my $Data = $self->myDecodeData($Table, $DB{ $KEY });

      # process all huge text data # 2.2
      foreach my $Key (keys %{$TextArea}) {
        &Standard::FileOpen(*TEXT, "rw", $DB::Path{ $Table }."/".$Data->{$PrimaryKey}.".$Key.txt.cgi");
          $Data->{$Key} = join("", <TEXT>);
        close (TEXT);
      }

      $Export .= $KEY."|~|".$self->myEncodeData( $Table, $Data )."\n";
    }
  untie (%DB);

  &Standard::FileOpen(*DB, "rw", $DB::Path{ $Table }."/$Table.counter");
    my $Counter = <DB>;
  close (DB);
  chomp($Counter);

  $Export .= "#".$Counter;

  &Standard::unLock("$Table.lock");

  return $Export;
}

###############################################################################
# Import function
# - function of import the table from database
sub Import {
  my $self = shift;
  my %in = ("CFG" => "", "TABLE" => "", "CONTENT" => [], @_);

  my $Table   = $in{'TABLE'}; # set current table
  my $Content = $in{'CONTENT'};

  require $in{'CFG'};
  &Standard::lock("$Table.lock");

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };
  my $TextArea    = $DB::TextArea   { $Table };

  $self->CreateTable(TABLE => $Table, VALUE => $DBTable, PRIMARY_KEY => $PrimaryKey);

  return 1 if ($#{ $Content } < 0);

  my @FIELDS = split(/\|/, $Content->[0]);
  my %FIELD;
  for (my $i = 0; $i <= $#FIELDS; $i++) {
    $FIELD{ $FIELDS[$i] } = $i;
  }

  my $Delimeter   = "|^|";
  my $unDelimeter = "|&|";

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || ($self->{'ERROR'} = "Can't open \"$DB::Path{ $Table }/$Table.db.cgi\" database. $!" and return);

  for (my $i = 1; $i < $#{$Content}; $i++) {
    my ($KEY, $STRING) = split (/\|\~\|/, $Content->[$i]);
    my $Data = $self->myDecodeData($Table, $STRING);

    # process all huge text data # 2.2
    foreach my $Key (keys %{$TextArea}) {
      &Standard::FileOpen(*TEXT, "w", $DB::Path{ $Table }."/".$Data->{ $PrimaryKey }.".$Key.txt.cgi");
        print TEXT $Data->{ $Key };
      close (DB);
      chmod(0666, $DB::Path{ $Table }."/".$Data->{ $PrimaryKey }.".$Key.txt.cgi");
      $Data->{ $Key } = $Data->{ $PrimaryKey }.".$Key.txt";
    }

    $DB{ $KEY } = $self->myEncodeData( $Table, $Data );
  }

  untie (%DB);

  my $Counter = $Content->[$#{ $Content }];
     $Counter =~ s/^#(\d+)$/$1/ig;
  &Standard::FileOpen(*DB, "w", $DB::Path{ $Table }."/$Table.counter");
    print DB $Counter;
  close (DB);

  &Standard::unLock("$Table.lock");

  return 1;
}

###############################################################################
# Count function
# - function of counting total records
sub Count {
  my $self = shift;
  my %in = ("TABLE" => "", @_);

  my $Table = $in{'TABLE'}; # set current table

  my $Count = 0;

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";
  &Standard::lock("$Table.lock");

  tie (my %DB, $AnyDBM_File::ISA[0], $DB::Path{ $Table }."/$Table.db.cgi", O_RDWR|O_CREAT, 0777) || ($self->{'ERROR'} = "Can't open \"$DB::Path{ $Table }/$Table.db.cgi\" database. $!" and return);
    foreach (keys %DB) {
      $Count++;
    }
  untie (%DB);

  &Standard::unLock("$Table.lock");

  return $Count;
}

###############################################################################
1; # end of Database.dbm.pm.pl file
###############################################################################