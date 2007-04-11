###############################################################################
# UltraBoard 2000 Database Engine (Oracle)                                    #
# Copyright (c) 1999-2000 UltraScripts.com, Inc. All Rights Reserved.         #
# UltraBoard is available from http://www.ub2k.com/ or                        #
# http://www.ultrascripts.com/                                                #
# Licenced to Gregory Nolle & PlasmaPulse Solutions for use in SuperDesk.     #
###############################################################################
package Database;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
require "Error.pm.pl";
require "Standard.pm.pl";

use DBI;
use File::Path;
use strict;

sub new {
  my ($class) = @_;
  my $self    = {};

  $self->{'DB'} ||= &Connect();
  $self->{'PREFIX'} = $SYSTEM->{'DB_PREFIX'} || "";
  
  $self->{'COL_PREFIX'} = "SD_";

  unless ($self->{'DB'}) {
    &Error::CGIError("Can't connect to $SYSTEM->{'DB_HOST'}->$SYSTEM->{'DB_NAME'} database. $DBI::errstr $!", "");
  }

  return bless ($self, $class);
}

sub DESTROY {
  my $self = shift;
  $self->Disconnect();
}

###############################################################################
# Connect function
# - function of connect to database
sub Connect {
  my %in = (
    "DRIVER"      => "Oracle",
    "DATABASE"    => $SYSTEM->{'DB_NAME'},
    "ORACLE_HOME" => $SYSTEM->{'DB_HOST'},
    "TNS_ADMIN"   => $SYSTEM->{'DB_PORT'},
    "USERNAME"    => $SYSTEM->{'DB_USERNAME'},
    "PASSWORD"    => $SYSTEM->{'DB_PASSWORD'},
    @_
  );

  $ENV{'ORACLE_HOME'} = $in{'ORACLE_HOME'};
  $ENV{'TNS_ADMIN'}   = $in{'TNS_ADMIN'};

  my $DSN  = "DBI:$in{'DRIVER'}:$in{'DATABASE'}";
  
  (my $DBH ||= DBI->connect($DSN, $in{'USERNAME'}, $in{'PASSWORD'}));

  return $DBH;
}

###############################################################################
# Disconnect function
# - function of disconnect from database
sub Disconnect {
  my $self = shift;

  my $DB = $self->{'DB'};

  $DB->disconnect() if ($DB);
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

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'};

  unless (mkdir ("$SYSTEM->{'DB_PATH'}/$Table", 0777)) {
    $self->{'ERROR'} = "Can't create a new table directory ($SYSTEM->{'DB_PATH'}/$Table). $!";
    return;
  }
  chmod (0777, "$SYSTEM->{'DB_PATH'}/$Table");

  my $Query = "CREATE TABLE $self->{'PREFIX'}$Table (";
  my @Fields;
  my @Keys = sort { $in{'VALUE'}->{$a}[0] <=> $in{'VALUE'}->{$b}[0] } keys %{ $in{'VALUE'} };
  for (my $i = 0; $i <= $#Keys; $i++) {
    my $Key = $Keys[$i];
    my $Pro = $in{'VALUE'}->{$Key};

    my $Field = "$self->{'COL_PREFIX'}$Key";

#    if ($Pro->[1] eq "autonumber") {
#      $Field .= " NUMBER($Pro->[2])";
#      $Field .= " UNSIGNED";
#    } elsif ($Pro->[1] eq "number") {
#      $Field .= " NUMBER($Pro->[2])";
#    } elsif ($Pro->[1] eq "string") {
#      if ($Pro->[2] <= 4000) {
#        $Field .= " VARCHAR2($Pro->[2])";
#      } else {
#        $Field .= " CLOB";
#      }
#    } elsif ($Pro->[1] eq "text") {
#      $Field .= " CLOB";
#    } else {
#      $Field .= " VARCHAR2(255)";
#    }

    if ($Pro->[1] eq "autonumber") {
      $Field .= " NUMBER($Pro->[2])";
#      $Field .= " UNSIGNED";
    } elsif ($Pro->[1] eq "number") {
      $Field .= " NUMBER($Pro->[2])";
    } elsif ($Pro->[1] eq "string") {
      if ($Pro->[2] <= 128) {
        $Field .= " CHAR($Pro->[2])";
      } elsif ($Pro->[2] < 256) {
        $Field .= " VARCHAR($Pro->[2])";
      } elsif ($Pro->[2] <= 1024) {
        $Field .= " CLOB";
      } else {
        $Field .= " VARCHAR(255)";
      }
    } elsif ($Pro->[1] eq "text") {
      $Field .= " CLOB";
    } else {
      $Field .= " CHAR(255)";
    }


    if ($Pro->[3]) {
      $Field .= " NOT NULL";
    }

    if ($Pro->[4] ne "") {
      $Field .= " DEFAULT '$Pro->[4]'";
    }
    
    if ($Key eq $in{'PRIMARY_KEY'}) {
      $Field .= " PRIMARY KEY";
    }

    $Query .= $Field;
    $Query .= "," unless ($i == $#Keys);
  }

#  $Query .= "PRIMARY KEY ($in{'PRIMARY_KEY'})";
  $Query .= ")";

  my $STH = $DB->prepare($Query);
	   $STH->execute() || ($self->{'ERROR'} = "Can't execute $Query. $DBI::errstr $!" and return);

  &Standard::FileOpen(*TABLE, "w", "$SYSTEM->{'DB_PATH'}/".$Table.".cfg");
    print TABLE <<TEXT;
package DB;

BEGIN { require "System.pm.pl";  import System  qw(\$SYSTEM ); }

\$DB::Path{'$Table'} = "\$SYSTEM->{'DB_PATH'}/$Table";

%{ \$DB::Table{'$Table'} } = (
TEXT
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

  return 1;
}

###############################################################################
# DropTables function
# - function of removing mult-tables at once from database
sub DropTables {
  my $self = shift;
  my %in = ("TABLES" => undef, @_);

  my $DB = $self->{'DB'};

  if ((ref ($in{'TABLES'}) eq "") and ($in{'TABLES'} eq "*")) {
    my $STH = $DB->prepare("SELECT * FROM USER_TABLES");
       $STH->execute();

    while (my @table = $STH->fetchrow_array()) {
      $self->DropTable(TABLE => $table[0]) || return;
    }
  } else {
    foreach my $table (@{$in{'TABLES'}}) {
      if ($table =~ /^$self->{'PREFIX'}(.+)$/i) {
        $self->DropTable(TABLE => $1) || return;
      } else {
      	$self->DropTable(TABLE => $table) || return;
      }
    }
  }

  return 1;
}

###############################################################################
# DropTable function
# - function of removing a table from database
sub DropTable {
  my $self = shift;
  my %in = ("TABLE" => "", @_);

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'};

  if ($Table =~ /^$self->{'PREFIX'}(.+)$/i) {
    $Table = $1;
  }

#  my $Query = "DROP TABLE IF EXISTS $self->{'PREFIX'}$Table";
  my $Query = "DROP TABLE $self->{'PREFIX'}$Table";

  my $STH = $DB->prepare($Query);
	   $STH->execute() || ($self->{'ERROR'} = "Can't execute $Query. $DBI::errstr $!" and return);

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

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";

  my $DBTable    = $DB::Table { $Table };
  my $PrimaryKey = $DB::PrimaryKey{ $Table };

  my (@Fields, @Values);
  foreach my $key (keys %{ $in{'VALUES'} } ) {
    next unless exists $DBTable->{$key};
    push (@Fields, "$self->{'COL_PREFIX'}$key");
    push (@Values, $DB->quote($in{'VALUES'}->{ $key }));
  }

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table READ");

  if ($DBTable->{$PrimaryKey}[1] eq "autonumber") {
    my $Query = "SELECT MAX($self->{'COL_PREFIX'}$PrimaryKey) FROM $self->{'PREFIX'}$Table";

    my $STH = $DB->prepare($Query);
       $STH->execute() || ($self->{'ERROR'} = "Can't query data to '$Table' table. Query: $Query. $DBI::errstr" and return);

    my $result = $STH->fetch();

    push (@Fields, $PrimaryKey);
    push (@Values, $result->[0] + 1);
    $in{'VALUES'}->{$PrimaryKey} = $result->[0] + 1;
  }

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table WRITE");

  my $Query = "INSERT INTO $self->{'PREFIX'}$Table (".join(", ", @Fields).") VALUES (".join(", ", @Values).")";
  $DB->do($Query) || ($self->{'ERROR'} = "Can't insert data to '$Table' table. $DBI::errstr" and return);

#  $DB->do("UNLOCK TABLES");

  $self->Synchronize($Table, "INSERT", $in{'VALUES'}) if $UB::SyncDSN{ $Table };

  return $in{'VALUES'}->{$PrimaryKey};
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

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

  if ($in{'KEY'} eq "") {
    $self->{'ERROR'} = "No primary key in table '$Table'.";
    return;
  }

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";

  my $PrimaryKey  = $DB::PrimaryKey{ $Table };

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table READ");

  my (@Fields);
  foreach my $key (keys %{ $in{'VALUES'} } ) {
    push (@Fields, "$self->{'COL_PREFIX'}$key");
  }

  my $Query = "SELECT ".join(", ", @Fields)." FROM $self->{'PREFIX'}$Table WHERE $self->{'COL_PREFIX'}$PrimaryKey = ".$DB->quote($in{'KEY'});

  my $STH = $DB->prepare($Query);
     $STH->execute() || ($self->{'ERROR'} = "The primary key is not found in table \"$Table\". $DBI::errstr" and return);

  my $Hash = $STH->fetchrow_hashref();

  unless ($in{'RESET'}) {
    foreach my $Key ( keys %{ $in{'VALUES'} } ) {
      next if ($Key eq $PrimaryKey);
      next if (($DB::Table{ $Table }->{$Key}[3] == 1) && ($in{'VALUES'}->{$Key} eq ""));

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

  @Fields = ();
  foreach my $key (keys %{ $Hash } ) {
    push (@Fields, $self->{'COL_PREFIX'}.$key."=".$DB->quote($Hash->{$key}));
  }

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table WRITE");

  $Query = "UPDATE $self->{'PREFIX'}$Table SET ".join(", ", @Fields)." WHERE $self->{'COL_PREFIX'}$PrimaryKey='$in{'KEY'}'";
  $DB->do($Query) || ($self->{'ERROR'} = "Can't update data to '$Table' table. $DBI::errstr" and return);

#  $DB->do("UNLOCK TABLES");

  $self->Synchronize($Table, "UPDATE", $in{'VALUES'}, $in{'KEY'}) if $UB::SyncDSN{ $Table };

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

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

  if ($#{ $in{'KEYS'} } < 0) {
    $self->{'ERROR'} = "No primary key for seaching in table '$Table'.";
    return;
  }

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";

  my $DBTable     = $DB::Table{ $Table };
  my $PrimaryKey  = $DB::PrimaryKey{ $Table };

#  $DB->do("LOCK TABLES $self->{'PREFIX'}$Table WRITE");

  for (my $i = 0; $i <= $#{ $in{'KEYS'} }; $i++) {
    my $Query = "DELETE FROM $self->{'PREFIX'}$Table WHERE $self->{'COL_PREFIX'}$PrimaryKey = '$in{'KEYS'}->[$i]'";
    $DB->do($Query) || ($self->{'ERROR'} = "Can't insert data to '$Table' table. $DBI::errstr" and return);
  }

#  $DB->do("UNLOCK TABLES");

  $self->Synchronize($Table, "UPDATE", $in{'VALUES'}, $in{'KEYS'}) if $UB::SyncDSN{ $Table };

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

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";

  my $PrimaryKey  = $DB::PrimaryKey{ $Table };

  my $Query = "SELECT";

  if ($in{'COUNT'}) {
    $Query .= " COUNT(*)";
  } else {
    if ( scalar @{ $in{'COLUMNS'} } > 0) {
      my @columns = map { "$self->{'COL_PREFIX'}$_" } @{ $in{'COLUMNS'} };
      $Query .= " ".join(", ", @columns);
    } else {
      $Query .= " *";
    }
  }

  $Query .= " FROM $self->{'PREFIX'}$Table";

  my @Where = ();
  my $BOOLEAN = " OR ";
     $BOOLEAN = " AND " if $in{'MATCH'} eq "ALL";

  FOREACH: foreach my $Field (keys %{ $in{'WHERE'} } ) {
    FOR: for (my $i = 0; $i <= $#{ $in{'WHERE'}->{$Field} }; $i++) {
      next FOR if $in{'WHERE'}->{$Field}[$i] =~ /\*$/;
      my $Statement = $in{'WHERE'}->{$Field}[$i];

      if ($Statement =~ /^=~(.+)$/) {
 #       push (@Where, "$Field REGEXP ".$DB->quote($1));
        push(@Where, "$self->{'COL_PREFIX'}$Field LIKE '%".$1."%'");
        next FOR;
      }

      if ($Statement =~ /^>(\d+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field > $1");
        next FOR;
      } elsif ($Statement =~ /^>(.+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field > ".$DB->quote($1));
        next FOR;
      }

      if ($Statement =~ /^<(\d+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field < $1");
        next FOR;
      } elsif ($Statement =~ /^<(.+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field < ".$DB->quote($1));
        next FOR;
      }

      if ($Statement =~ /^!=(\d+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field != $1");
        next FOR;
      } elsif ($Statement =~ /^!=(.+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field != ".$DB->quote($1));
        next FOR;
      }

      if ($DB::Table{$Table}->{$Field}->[1] =~ /number$/ && $Statement =~ /^=?(\d+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field = $1");
        next FOR;
      } elsif ($Statement =~ /^=?(.+)$/) {
        push (@Where, "$self->{'COL_PREFIX'}$Field = ".$DB->quote($1));
        next FOR;
      }
    }
  }

  $Query .= " WHERE ".join ($BOOLEAN, @Where) unless $#Where < 0;

  $Query .= " ORDER BY $self->{'COL_PREFIX'}$in{'SORT'}" if $in{'SORT'};

  if ($in{'BY'} eq "Z-A") {
    $Query .= " DESC";
  } elsif ($in{'BY'} eq "A-Z") {
    $Query .= " ASC";
  }

  if ($in{'TO'}) {
    my ($From, $To) = split (/-/, $in{'TO'});

    my $Total = $To - $From + 1;

    $Query .= " LIMIT";
    $Query .= " $From," if $From;
    $Query .= " $Total";
  }

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table READ");

#  my $STH = $DB->prepare($Query);
  my $STH = $DB->prepare($Query) || &Error::CGIError("Error preparing $Query. $DBI::errstr", "");
     $STH->execute() || ($self->{'ERROR'} = "Can't query the data from \"$Table\". $DBI::errstr" and return);

  return $STH->fetchrow_array() if ($in{'COUNT'});

  my (@Return, %Index);
  while(my $row = $STH->fetchrow_hashref()){
    push (@Return, $self->myRemovePrefix($row));
    $Index{ $row->{ $PrimaryKey } } = $#Return;
  }

#  $DB->do("UNLOCK TABLES");

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

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

  if ($in{'KEY'} eq "") {
    $self->{'ERROR'} = "No primary key in table '$Table'.";
    return;
  }

  require "$SYSTEM->{'DB_PATH'}/$Table.cfg";

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table READ");

  my $PrimaryKey  = $DB::PrimaryKey { $Table };

  my $Query = "SELECT";

  my (@Fields);
  if ( scalar @{ $in{'COLUMNS'} } > 0) {
    my @columns = map { "$self->{'COL_PREFIX'}$_" } @{ $in{'COLUMNS'} };
    $Query .= " ".join(", ", @columns);
  } else {
    $Query .= " *";
  }

  $Query .= " FROM $self->{'PREFIX'}$Table WHERE $self->{'COL_PREFIX'}$PrimaryKey=".$DB->quote($in{'KEY'});

  my $STH = $DB->prepare($Query);
     $STH->execute() || ($self->{'ERROR'} = "Can't query the data from \"$Table\". $DBI::errstr" and return);

  my $result = $STH->fetchrow_hashref();

#  $DB->do("UNLOCK TABLES");

  return $self->myRemovePrefix($result);
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

    $tmp    =~ s/^\s+//g;
    $tmp    =~ s/\s+$//g;

    $tmp    =~ s/\r//g;
    $tmp    =~ s/\n/\\n/g;

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
# Export function
# - function of export the table from database
sub Export {
  my $self = shift;
  my %in = ("CFG" => "", "TABLE" => "", @_);

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

  require $in{'CFG'};

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table READ");

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };

  my $Export = join ("|", @{$Columns})."\n";

  my $Counter = 0;

  my $Query = "SELECT * FROM $self->{'PREFIX'}$Table ORDER BY $self->{'COL_PREFIX'}$PrimaryKey ASC";

  my $STH = $DB->prepare($Query);
     $STH->execute() || ($self->{'ERROR'} = "Can't query the data from \"$Table\". $DBI::errstr" and return);

  while (my $row = $STH->fetchrow_hashref()) {
    my $encoded = $self->myEncodeData($Table, $self->myRemovePrefix($row));
    $Export .= $row->{ $PrimaryKey }."|~|".$encoded."\n";
  }

  if ($DBTable->{$PrimaryKey}[1] eq "autonumber") {
    my $Query = "SELECT $self->{'COL_PREFIX'}$PrimaryKey FROM $self->{'PREFIX'}$Table ORDER BY $self->{'COL_PREFIX'}$PrimaryKey DESC LIMIT 1";

    my $STH = $DB->prepare($Query);
       $STH->execute() || ($self->{'ERROR'} = "Can't query the data from \"$Table\". $DBI::errstr" and return);

    my $result = $STH->fetchrow_hashref();

    $Export .= "#".$result->{$self->{'COL_PREFIX'}.$PrimaryKey};
  } else {
    $Export .= "#".$STH->rows();
  }

#  $DB->do("UNLOCK TABLES");

  return $Export;
}

###############################################################################
# Import function
# - function of import the table from database
sub Import {
  my $self = shift;
  my %in = ("CFG" => "", "TABLE" => "", "CONTENT" => [], @_);

  my $DB      = $self->{'DB'};
  my $Table   = $in{'TABLE'}; # set current table
  my $Content = $in{'CONTENT'};

  require $in{'CFG'};

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };

  $self->CreateTable(TABLE => $Table, VALUE => $DBTable, PRIMARY_KEY => $PrimaryKey);

  return 1 if ($#{ $Content } < 0);

  my @FIELDS = split(/\|/, $Content->[0]);
  my %FIELD;
  for (my $i = 0; $i <= $#FIELDS; $i++) {
    $FIELD{ $FIELDS[$i] } = $i;
  }

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table WRITE");

  my %KEYs;
  for (my $i = 1; $i < $#{$Content}; $i++) {
    my ($KEY, $STRING) = split (/\|\~\|/, $Content->[$i]);
    my $Data = $self->myDecodeData($Table, $STRING);

    next if $KEYs{ $Data->{ $PrimaryKey } };

    my (@Values, @Columns);
    foreach my $Column ( @{ $Columns } ) {
      next unless exists $DBTable->{$Column};
      push (@Columns, "$self->{'COL_PREFIX'}$Column");
      push (@Values, $DB->quote($Data->{ $Column }));
    }

    my $Query = "INSERT INTO $self->{'PREFIX'}$Table (".join(", ", @Columns).") VALUES (".join(", ", @Values).")";
    $DB->do($Query) || ($self->{'ERROR'} = "Can't insert data to '$Table' table. $DBI::errstr" and return);

    $KEYs{ $Data->{ $PrimaryKey } } = 1;
  }

#  $DB->do("UNLOCK TABLES");

  return 1;
}

###############################################################################
# Count function
# - function of counting total records
sub Count {
  my $self = shift;
  my %in = ("TABLE" => "", @_);

  my $DB    = $self->{'DB'};
  my $Table = $in{'TABLE'}; # set current table

#  $DB->do("LOCK TABLE $self->{'PREFIX'}$Table READ");

  my $Query = "SELECT COUNT(*) FROM $self->{'PREFIX'}$Table";
  my $STH = $DB->prepare($Query);
     $STH->execute() || ($self->{'ERROR'} = "Can't query the data from \"$Table\". $DBI::errstr" and return);

  my $Count = $STH->fetchrow_array();

#  $DB->do("UNLOCK TABLES");

  return $Count;
}

###############################################################################
# Synchronize function
sub Synchronize {
  my $self = shift;
  my ($Table, $Function, $Values, $Keys) = @_;

  my $SyncFields = $DB::Synchronize{ $Table };
  my $SyncTable  = $DB::SyncTBE{ $Table };
  my $SyncKey    = $DB::SyncKey{ $Table };

  my $DBH ||= DBI->connect($DB::SyncDSN{ $Table }, $DB::SyncUSR{ $Table }, $DB::SyncPWD{ $Table });

#  $DBH->do("LOCK TABLE $SyncTable WRITE");

  if ($Function eq "INSERT") {
    my (@Fields, @Values);
    foreach my $key (keys %{ $Values } ) {
      next unless exists $SyncFields->{$key};
      push (@Fields, "$self->{'COL_PREFIX'}$key");
      push (@Values, $DBH->quote($Values->{ $key }));
    }

    my $Query = "INSERT INTO $SyncTable (".join(", ", @Fields).") VALUES (".join(", ", @Values).")";
    $DBH->do($Query) || ($self->{'ERROR'} = "Can't insert data to '$SyncTable' synchronize table. $DBI::errstr" and return);
  } elsif ($Function eq "UPDATE") {
    my @Fields;
    foreach my $key (keys %{ $Values } ) {
      push (@Fields, $self->{'COL_PREFIX'}.$key."=".$DBH->quote($Values->{$key}));
    }

    my $Query = "UPDATE $SyncTable SET ".join(", ", @Fields)." WHERE $SyncKey='".$Keys."'";
    $DBH->do($Query) || ($self->{'ERROR'} = "Can't update data to '$SyncTable' synchronize table. $DBI::errstr" and return);
  } elsif ($Function eq "DELETE") {
    for (my $i = 0; $i <= $#{ $Keys }; $i++) {
      my $Query = "DELETE FROM $SyncTable WHERE $SyncKey = '$Keys->[$i]'";
      $DBH->do($Query) || ($self->{'ERROR'} = "Can't delete data to '$SyncTable' synchronize table. $DBI::errstr" and return);
    }
  }

#  $DBH->do("UNLOCK TABLES");

  $DBH->disconnect();
}

###############################################################################
# undocument function (for mysql only)
###############################################################################
# to enable synchronize feature between ub database and another database
# you have to add following variables into ub database config file (*.cfg)
# in database directory. after you done that, ub will start synchronize any
# insert, update, delete action to your another database. however it won't
# update the ub data from your another database, unless you modify the sources
# from your script to synchronize back to ub database.
#
# P.S. it is helpful if you have another members database from antoher program
#      and you want ub use that database. remember you have to add all data
#      from your another member database into ub database first!
###############################################################################
# the data source name on another database
# $UB::SyncDSN{'Accounts'} = "DBI:mysql:$SYSTEM->{'DB_NAME'}:$in{'IP'}";
#
# the username on another database
# $UB::SyncUSR{'Accounts'} = $SYSTEM->{'DB_USERNAME'};
#
# the password on another database
# $UB::SyncPWD{'Accounts'} = $SYSTEM->{'DB_PASSWORD'};
#
# the table on another database
# $UB::SyncTBE{'Accounts'} = "Accounts";
#
# the primary key on another database (must same as primary key of the table)
# $DB::SyncKey{'Accounts'} = "USERNAME";
#
# %{ $DB::Synchronize{'Accounts'} } = (
#   the fields the you want to synchronize from ub to another database
#   ultraboard field => another database table field
#   "EMAIL" => "EMAIL"
# );
###############################################################################

###############################################################################
# CGIError function
# - prints the details of a CGI error.
sub CGIError {
  my $self = shift;
  my ($message, $path) = @_;

  my ($key, $space);

  # print the html header
  print "Content-type: text/html\n\n";

  $message =~ s/\n/<br>/g;

#  open (ERROR_LOG, ">>$SYSTEM->{'LOGS_PATH'}/error.log.txt");
#    print ERROR_LOG "|^|500|^|$message|^|$path|^|$ENV{'REMOTE_ADDR'}|^|".time."\n";
#  close (ERROR_LOG);
#  chmod (0777, "$SYSTEM->{'LOGS_PATH'}/error.log.txt");

  print "<html>\n";
  print "<head>\n";
  print "<title>CGI Script Error</title>\n";
  print "</head>\n";
  print "<body marginheight=\"5\" marginwidth=\"5\" leftmargin=\"5\" topmargin=\"5\" rightmargin=\"5\">\n";
  print "<font face=\"Verdana\">\n";
  print "<font size=\"4\"><b>CGI Script Error</b></font><p>\n";
  print "<font size=\"2\">\n";

  # printing error message
  #$message =~ s/\n/<br>\n/g;
  $message and print $message;
  print "<p>";

  # printing general infomation
  print "<font size=\"4\"><b>General Infomation</b></font><p>\n";
  print "<table cellpadding=\"0\" cellspacing=\"0\">\n";

  if ($path) {
    $path =~ s/\\/\//g;
    print "<tr>\n";
    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>Error Path</b></font></td>\n";
    print "<td><font face=\"Verdana\" size=\"2\">$path</font></td>\n";
    print "</tr>\n";
  }
  if ($0) {
    $0 =~ s/\\/\//g;
    print "<tr>\n";
    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>Script Path</b></font></td>\n";
    print "<td><font face=\"Verdana\" size=\"2\">$0</font></td>\n";
    print "</tr>\n";
  }
  if ($]) {
    print "<tr>\n";
    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>Perl Version</b></font></td>\n";
    print "<td><font face=\"Verdana\" size=\"2\">$]</font></td>\n";
    print "</tr>\n";
  }
#  if ($UB::VERSION) {
#    print "<tr>\n";
#    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>UltraBoard Version</b></font></td>\n";
#    print "<td><font face=\"Verdana\" size=\"2\">$UB::VERSION</font></td>\n";
#    print "</tr>\n";
#  }
#  if ($CGI::VERSION) {
#    print "<tr>\n";
#    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>CGI.pm Version</b></font></td>\n";
#    print "<td><font face=\"Verdana\" size=\"2\">$CGI::VERSION</font></td>\n";
#    print "</tr>\n";
#  }
  print "</table><p>\n";

#  if (defined %UB::QUERY) {
#    # printing form variables
#    print "<font size=\"4\"><b>Form Variables</b></font><p>\n";
#    print "<table cellpadding=\"0\" cellspacing=\"0\">\n";
#    foreach my $KEY (sort keys %UB::QUERY) {
#      print "<tr>\n";
#      print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>$KEY</b></font></td>\n";
#      print "<td><font face=\"Verdana\" size=\"2\">".$UB::QUERY{$KEY}."</font></td>\n";
#      print "</tr>\n";
#    }
#    print "</table><p>\n";
#  }

  # printing environment variables
  print "<font size=\"4\"><b>Environment Variables</b></font><p>\n";
  print "<table cellpadding=\"0\" cellspacing=\"0\">\n";
  foreach $key (sort keys %ENV) {
    print "<tr>\n";
    print "<td width=\"200\" valign=\"TOP\"><font face=\"Verdana\" size=\"2\"><b>$key</b></font></td>\n";
    print "<td><font face=\"Verdana\" size=\"2\">".$ENV{$key}."</font></td>\n";
    print "</tr>\n";
  }
  print "</table><p>\n";
  print "</font>\n";
  print "</font>\n";
  print "</body>\n";
  print "</html>\n";

  exit;
}

###############################################################################
# FileOpen function
# - function of open a file for better error handling.
sub FileOpen {
  my $self = shift;
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
# - function of locking files without using build-in function 'flock()'.
sub lock {
  my $self = shift;
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
# - function of unlocking files without using build-in function 'flock()'.
sub unLock {
  my $self = shift;
  my ($file) = @_;

  close(LOCK);

  unlink("$SYSTEM->{'TEMP_PATH'}/$file");
}

###############################################################################
# myRemovePrefix function
sub myRemovePrefix {
  my $self = shift;
  my ($Row) = @_;

  foreach my $column (keys %{ $Row }) {
    my $value = $Row->{ $column };
    delete($Row->{ $column });
    
    $column =~ s/^\Q$self->{'COL_PREFIX'}\E//;
    $Row->{ $column } = $value;
  }
  
  return $Row;
}

###############################################################################
1; # end of Database.mysql.pm file
###############################################################################