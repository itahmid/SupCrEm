###############################################################################
# UltraBoard 2000 Database Engine (Microsoft SQL Server)                      #
# Copyright (c) 1999-2000 UltraScripts.com, Inc. All Rights Reserved.         #
# UltraBoard is available from http://www.ub2k.com/ or                        #
# http://www.ultrascripts.com/                                                #
# Licenced to Gregory Nolle & PlasmaPulse Solutions for use in SuperDesk.     #
###############################################################################
package Database;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
require "Error.pm.pl";
require "Standard.pm.pl";

use Win32::ODBC;
use File::Path;
use strict;

sub new {
  my ($class) = @_;
  my $self    = {};

  $self->{'DB'} ||= &Connect();
  $self->{'PREFIX'} = $SYSTEM->{'DB_PREFIX'} || "";

  unless ($self->{'DB'}->{'connection'}) {
    &Error::CGIError("Can't connect to $SYSTEM->{'DB_NAME'} database. ".$self->{'DB'}->Error." $!", "");
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
    "DATABASE" => $SYSTEM->{'DB_NAME'},
    "USERNAME" => $SYSTEM->{'DB_USERNAME'},
    "PASSWORD" => $SYSTEM->{'DB_PASSWORD'},
    @_
  );

  my $DSN = "dsn=$in{'DATABASE'}";
     $DSN .= "; uid=$in{'USERNAME'}" if $in{'USERNAME'};
     $DSN .= "; pwd=$in{'PASSWORD'}" if $in{'PASSWORD'};

  my $DBH = new Win32::ODBC($DSN);

  return $DBH;
}

###############################################################################
# Disconnect function
# - function of disconnect from database
sub Disconnect {
  my $self = shift;

  my $DB = $self->{'DB'};

  $DB->Close() if ($DB);
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

    my $Field = "$Key";

    if ($Pro->[1] eq "autonumber") {
      if ($Pro->[2] <= 3) {
        $Field .= " TINYINT";
      } elsif ($Pro->[1] <= 5) {
        $Field .= " SMALLINT";
      } elsif ($Pro->[1] <= 10) {
        $Field .= " INT";
      } elsif ($Pro->[1] <= 19) {
        $Field .= " DECIMAL($Pro->[2],0)";
      } else {
        $Field .= " INT";
      }
    } elsif ($Pro->[1] eq "number") {
      if ($Pro->[2] <= 3) {
        $Field .= " TINYINT";
      } elsif ($Pro->[2] <= 5) {
        $Field .= " SMALLINT";
      } elsif ($Pro->[2] <= 10) {
        $Field .= " INT";
      } elsif ($Pro->[2] <= 19) {
        $Field .= " DECIMAL($Pro->[2],0)";
      } else {
        $Field .= " INT";
      }
    } elsif ($Pro->[1] eq "string") {
      if ($Pro->[2] <= 128) {
        $Field .= " CHAR($Pro->[2])";
      } elsif ($Pro->[2] <= 1024) {
        $Field .= " VARCHAR($Pro->[2])";
      } else {
        $Field .= " VARCHAR(255)";
      }
    } elsif ($Pro->[1] eq "text") {
      $Field .= " TEXT";
    } else {
      $Field .= " CHAR(255)";
    }

    if ($Pro->[3]) {
      $Field .= " NOT NULL";
    }

    if ($Pro->[4] ne "") {
      $Field .= " DEFAULT '$Pro->[4]'";
    }

    $Query .= $Field.",";
  }

  $Query .= "PRIMARY KEY ($in{'PRIMARY_KEY'})";
  $Query .= ");";

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't execute $Query. ".$DB->Error." $!";
    return;
  }

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
    while (my @table = $DB->TableList()) {
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

  my $Query = "DROP TABLE $self->{'PREFIX'}$Table";

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't execute $Query. ".$DB->Error." $!";
    return;
  }

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
    push (@Fields, $key);
    push (@Values, &myQuote($in{'VALUES'}->{ $key }));
  }

  if ($DBTable->{$PrimaryKey}[1] eq "autonumber") {
    my $Query = "SELECT MAX($PrimaryKey) FROM $self->{'PREFIX'}$Table";

    if ($DB->Sql($Query)) {
      $self->{'ERROR'} = "Can't query data to '$Table' table. Query: $Query. ".$DB->Error." $!";
      return;
    }

    $DB->FetchRow();
    my $result = $DB->Data();

    push (@Fields, $PrimaryKey);
    push (@Values, $result + 1);
    $in{'VALUES'}->{$PrimaryKey} = $result + 1;
  }

  my $Query = "INSERT INTO $self->{'PREFIX'}$Table (".join(", ", @Fields).") VALUES (".join(", ", @Values).")";

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't insert data to '$Table' table. Query: $Query. ".$DB->Error." $!";
    return;
  }

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

  my (@Fields);
  foreach my $key (keys %{ $in{'VALUES'} } ) {
    push (@Fields, $key);
  }

  my $Query = "SELECT ".join(", ", @Fields)." FROM $self->{'PREFIX'}$Table WHERE $PrimaryKey = ".&myQuote($in{'KEY'});

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "The primary key is not found in table \"$Table\". Query: $Query. ".$DB->Error." $!";
    return;
  }

  $DB->FetchRow();
  my $Hash = { $DB->DataHash() };

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
    push (@Fields, $key."=".&myQuote($Hash->{$key}));
  }

  $Query = "UPDATE $self->{'PREFIX'}$Table SET ".join(", ", @Fields)." WHERE $PrimaryKey='$in{'KEY'}'";

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't update data to '$Table' table. Query: $Query. ".$DB->Error." $!";
    return;
  }

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

  for (my $i = 0; $i <= $#{ $in{'KEYS'} }; $i++) {
    my $Query = "DELETE FROM $self->{'PREFIX'}$Table WHERE $PrimaryKey = '$in{'KEYS'}->[$i]'";
    if ($DB->Sql($Query)) {
      $self->{'ERROR'} = "Can't insert data to '$Table' table. Query: $Query. ".$DB->Error." $!";
      return;
    }
  }

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
      $Query .= " ".join(", ", @{ $in{'COLUMNS'} });
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
        push (@Where, "$Field LIKE ".&myQuote("%".$1."%"));
        next FOR;
      }

      if ($Statement =~ /^>(\d+)$/) {
        push (@Where, "$Field > $1");
        next FOR;
      } elsif ($Statement =~ /^>(.+)$/) {
        push (@Where, "$Field > ".&myQuote($1));
        next FOR;
      }

      if ($Statement =~ /^<(\d+)$/) {
        push (@Where, "$Field < $1");
        next FOR;
      } elsif ($Statement =~ /^<(.+)$/) {
        push (@Where, "$Field < ".&myQuote($1));
        next FOR;
      }

      if ($Statement =~ /^!=(\d+)$/) {
        push (@Where, "$Field != $1");
        next FOR;
      } elsif ($Statement =~ /^!=(.+)$/) {
        push (@Where, "$Field != ".&myQuote($1));
        next FOR;
      }

      if ($DB::Table{$Table}->{$Field}->[1] =~ /number$/ && $Statement =~ /^=?(\d+)$/) {
        push (@Where, "$Field = $1");
        next FOR;
      } elsif ($Statement =~ /^=?(.+)$/) {
        push (@Where, "$Field = ".&myQuote($1));
        next FOR;
      }
    }
  }

  $Query .= " WHERE ".join ($BOOLEAN, @Where) unless $#Where < 0;

  $Query .= " ORDER BY $in{'SORT'}" if $in{'SORT'};

  if ($in{'BY'} eq "Z-A") {
    $Query .= " DESC";
  } elsif ($in{'BY'} eq "A-Z") {
    $Query .= " ASC";
  }

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't query the data from \"$Table\". Query: $Query. ".$DB->Error." $!";
    return;
  }

  if ($in{'COUNT'}) {
    $DB->FetchRow();
    return $DB->Data();
  }

  my (@Return, %Index);
  while ($DB->FetchRow()){
    my $row = { $DB->DataHash() };
    push (@Return, $row);
  }

  if ($in{'TO'}) {
    my ($From, $To) = split (/-/, $in{'TO'});

    $From = 0        if (($From eq "") || ($From < 0       ));
    $To   = $#Return if (($To   eq "") || ($To   > $#Return));

    @Return = @Return[$From..$To];
  }

  for (my $i = 0; $i <= $#Return; $i++) {
    $Index{ $Return[$i]{ $PrimaryKey } } = $i;
  }

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

  my $PrimaryKey  = $DB::PrimaryKey { $Table };

  my $Query = "SELECT";

  my (@Fields);
  if ( scalar @{ $in{'COLUMNS'} } > 0) {
    $Query .= " ".join(", ", @{ $in{'COLUMNS'} });
  } else {
    $Query .= " *";
  }

  $Query .= " FROM $self->{'PREFIX'}$Table WHERE $PrimaryKey=".&myQuote($in{'KEY'});

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't query the data from \"$Table\". Query: $Query. ".$DB->Error." $!";
    return;
  }

  $DB->FetchRow();
  my $result = { $DB->DataHash() };

  return $result;
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
# myQuote function (Private)
# - function of quote the data
sub myQuote {
  my ($data) = @_;

  if ($data eq "") {
    return "NULL";
  } else {
    $data =~ s/'/''/g;
    return "'$data'";
  }
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

  my $DBTable     = $DB::Table      { $Table };
  my $PrimaryKey  = $DB::PrimaryKey { $Table };
  my $Columns     = $DB::Columns    { $Table };

  my $Export = join ("|", @{$Columns})."\n";

  my $Counter = 0;

  my $Query = "SELECT * FROM $self->{'PREFIX'}$Table ORDER BY $PrimaryKey ASC";

  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't query the data from \"$Table\". Query: $Query. ".$DB->Error." $!";
    return;
  }

  while ($DB->FetchRow()) {
    my $row = { $DB->DataHash() };
    my $encoded = $self->myEncodeData($Table, $row);
    $Export .= $row->{ $PrimaryKey }."|~|".$encoded."\n";
  }

  if ($DBTable->{$PrimaryKey}[1] eq "autonumber") {
    my $Query = "SELECT MAX($PrimaryKey) FROM $self->{'PREFIX'}$Table";

    if ($DB->Sql($Query)) {
      $self->{'ERROR'} = "Can't query the data from \"$Table\". Query: $Query. ".$DB->Error." $!";
      return;
    }

    $DB->FetchRow();
    my $result = { $DB->DataHash() };

    $Export .= "#".$result->{$PrimaryKey};
  } else {
    $Export .= "#".$DB->RowCount();
  }

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

  my %KEYs;
  for (my $i = 1; $i < $#{$Content}; $i++) {
    my ($KEY, $STRING) = split (/\|\~\|/, $Content->[$i]);
    my $Data = $self->myDecodeData($Table, $STRING);

    next if $KEYs{ $Data->{ $PrimaryKey } };

    my @Values;
    foreach my $Column ( @{ $Columns } ) {
      next unless exists $DBTable->{$Column};
      push (@Values, &myQuote($Data->{ $Column }));
    }

    my $Query = "INSERT INTO $self->{'PREFIX'}$Table (".join(", ", @{ $Columns }).") VALUES (".join(", ", @Values).")";

    if ($DB->Sql($Query)) {
      $self->{'ERROR'} = "Can't insert data to '$Table' table. Query: $Query. ".$DB->Error." $!";
      return;
    }

    $KEYs{ $Data->{ $PrimaryKey } } = 1;
  }

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

  my $Query = "SELECT COUNT(*) FROM $self->{'PREFIX'}$Table";
  if ($DB->Sql($Query)) {
    $self->{'ERROR'} = "Can't query the data from \"$Table\". Query: $Query. ".$DB->Error." $!";
    return;
  }

  $DB->FetchRow();
  return $DB->Data();
}

###############################################################################
1; # end of Database.mssql.pm file
###############################################################################