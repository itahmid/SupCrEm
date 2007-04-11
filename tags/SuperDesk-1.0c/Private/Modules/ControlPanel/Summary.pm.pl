###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/Summary.pm.pl -> Summary module                                #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::Summary;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";

use strict;

require "ControlPanel/Output/Summary.pm.pl";

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
  
  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Getting data...                                                      #

  my ($Tickets, $TicketsIndex) = $in{'DB'}->Query(TABLE => "Tickets");

  my %INPUT;
  
  $INPUT{'TOTALS'}->{'TICKETS'} = scalar(@{ $Tickets });
  $INPUT{'TOTALS'}->{'UNRESOLVED_TICKETS'} = scalar(grep { $_->{'STATUS'} <= 50 } @{$Tickets});
  $INPUT{'TOTALS'}->{'RESOLVED_TICKETS'} = scalar(grep { $_->{'STATUS'} >= 60 } @{$Tickets});

  $INPUT{'TOTALS'}->{'CATEGORIES'} = $in{'DB'}->Query(
    TABLE => "Categories",
    COUNT => 1
  );

  $INPUT{'TOTALS'}->{'USERS'} = $in{'DB'}->Query(
    TABLE => "UserAccounts",
    COUNT => 1
  );

  $INPUT{'TOTALS'}->{'STAFF'} = $in{'DB'}->Query(
    TABLE => "StaffAccounts",
    COUNT => 1
  );

  eval "use LWP::Simple";
  unless ($@) {
    my $result = getstore("http://www.plasmapulse.com/?sc=Version&Product=sd&Edition=se", "$SYSTEM->{'TEMP_PATH'}/version.ver");
    if ($result eq "200") {
      &Standard::FileOpen(*VERSION, "r", "$SYSTEM->{'TEMP_PATH'}/version.ver");
      $INPUT{'LATEST_VERSION'} = join("", <VERSION>);
      close(VERSION);
      unlink("$SYSTEM->{'TEMP_PATH'}/version.ver") || &Error::CGIError("Error removing temporary version file. $!", "$SYSTEM->{'TEMP_PATH'}/version.ver");
    }
  }

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::Summary->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT);
  
  return 1;
}

1;