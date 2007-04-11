###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Authenticate.pm.pl -> Authenticate library                                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Authenticate;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";

use strict;

###############################################################################
# CP function
sub CP {
  my %in = (DB => undef, REQUIRE_SUPER => 0, @_);

  my $Account;
  
  if ($SD::QUERY{'Username'} && $SD::QUERY{'Password'}) {
    $Account = $in{'DB'}->BinarySelect(
      TABLE => "StaffAccounts",
      KEY   => $SD::QUERY{'Username'}
    );
    unless ($Account) {
      require "ControlPanel/Login.pm.pl";
      my $Source = CP::Login->new();
         $Source->show(DB => $in{'DB'}, ERROR => "INVALID-Username");
      exit;
    }
    unless ($SD::QUERY{'Password'} eq $Account->{'PASSWORD'}) {
      require "ControlPanel/Login.pm.pl";
      my $Source = CP::Login->new();
         $Source->show(DB => $in{'DB'}, ERROR => "INVALID-Password");
      exit;
    }
  } elsif ($SD::COOKIES{'CP-Username'} && $SD::COOKIES{'CP-Password'}) {
    $Account = $in{'DB'}->BinarySelect(
      TABLE => "StaffAccounts",
      KEY   => $SD::COOKIES{'CP-Username'}
    );
    if (!$Account || $SD::COOKIES{'CP-Password'} ne $Account->{'PASSWORD'}) {
      $SD::COOKIES{'CP-Username'} = "";
      $SD::COOKIES{'CP-Password'} = "";

      require "ControlPanel/Login.pm.pl";
      my $Source = CP::Login->new();
         $Source->show(DB => $in{'DB'});
      exit;
    }
  } else {
    require "ControlPanel/Login.pm.pl";
    my $Source = CP::Login->new();
       $Source->show(DB => $in{'DB'});
    exit;
  }
  
  %SD::ADMIN = (%SD::ADMIN, %{ $Account });

  if ($in{'REQUIRE_SUPER'} && $SD::ADMIN{'LEVEL'} != 100) {
    &Error::Error("CP", MESSAGE => "You do not have sufficient rights to access this feature");
  }

  if ($SD::ADMIN{'STATUS'} != 50) {
    &Error::Error("CP", MESSAGE => "Your account is inactive");
  }

  return 1;
}

###############################################################################
# SD function
sub SD {
  my %in = (DB => undef, REQUIRE_AUTH => 1, @_);

  my ($Session, $Account);

  MANUAL: if ($SD::QUERY{'Username'} && $SD::QUERY{'Password'}) {
    $Account = $in{'DB'}->BinarySelect(
      TABLE => "UserAccounts",
      KEY   => $SD::QUERY{'Username'}
    );
    unless ($Account) {
      require "Login.pm.pl";
      my $Source = Login->new();
         $Source->show(DB => $in{'DB'}, ERROR => "INVALID-Username");
      exit;
    }
    unless ($SD::QUERY{'Password'} eq $Account->{'PASSWORD'}) {
      require "Login.pm.pl";
      my $Source = Login->new();
         $Source->show(DB => $in{'DB'}, ERROR => "INVALID-Password");
      exit;
    }
    
    $Session = {
      USERNAME      => $SD::QUERY{'Username'},
      PASSWORD      => $SD::QUERY{'Password'},
      IP            => $ENV{'REMOTE_ADDR'},
      LOGIN_SECOND  => time
    };
    
    (
      $Session->{'ID'} = $in{'DB'}->Insert(
        TABLE   => "Sessions",
        VALUES  => $Session
      )
    ) || &Error::Error("SD", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");
    
    $SD::COOKIES{'SID'} = $Session->{'ID'};
    goto END;
  }
  
  SID: if ($SD::QUERY{'SID'}) {
    $Session = $in{'DB'}->BinarySelect(
      TABLE   => "Sessions",
      KEY     => $SD::QUERY{'SID'}
    );
    
    goto COOKSID unless ($Session);
    goto COOKSID unless ($Session->{'IP'} eq $ENV{'REMOTE_ADDR'});
    
    if ($Session->{'LOGIN_SECOND'} < (time - 30 * 24 * 60 * 60)) {
      (
        $in{'DB'}->Delete(
          TABLE   => "Sessions",
          KEYS    => [$SD::QUERY{'SID'}]
        )
      ) || &Error::Error("SD", MESSAGE => "Error deleting record. $in{'DB'}->{'ERROR'}");
      goto COOKSID;
    }
    
    $Account = $in{'DB'}->BinarySelect(
      TABLE => "UserAccounts",
      KEY   => $Session->{'USERNAME'}
    );
    
    goto COOKSID unless ($Account);
    goto COOKSID unless ($Account->{'PASSWORD'} eq $Session->{'PASSWORD'});
    
    (
      $in{'DB'}->Update(
        TABLE   => "Sessions",
        VALUES  => {
          LOGIN_SECOND  => time
        },
        KEY     => $SD::QUERY{'SID'}
      )
    ) || &Error::Error("SD", MESSAGE => "Error updating record.1 $in{'DB'}->{'ERROR'}");
    
    $SD::COOKIES{'SID'} = $SD::QUERY{'SID'};
    goto END;
  }
  
  COOKSID: if ($SD::COOKIES{'SID'}) {
    $Session = $in{'DB'}->BinarySelect(
      TABLE   => "Sessions",
      KEY     => $SD::COOKIES{'SID'}
    );
    if (!$Session || $Session->{'IP'} ne $ENV{'REMOTE_ADDR'}) {
      $SD::COOKIES{'SID'} = "";
      goto COOKMANUAL;
    }
    
    if ($Session->{'LOGIN_SECOND'} < (time - 30 * 24 * 60 * 60)) {
      (
        $in{'DB'}->Delete(
          TABLE   => "Sessions",
          KEYS    => [$SD::COOKIES{'SID'}]
        )
      ) || &Error::Error("SD", MESSAGE => "Error deleting record. $in{'DB'}->{'ERROR'}");
      $SD::COOKIES{'SID'} = "";
      goto COOKMANUAL;
    }
    
    $Account = $in{'DB'}->BinarySelect(
      TABLE => "UserAccounts",
      KEY   => $Session->{'USERNAME'}
    );

    if (!$Account || $Account->{'PASSWORD'} ne $Session->{'PASSWORD'}) {    
      $SD::COOKIES{'SID'} = "";
      goto COOKMANUAL;
    }
    
    (
      $in{'DB'}->Update(
        TABLE   => "Sessions",
        VALUES  => {
          LOGIN_SECOND  => time
        },
        KEY     => $SD::COOKIES{'SID'}
      )
    ) || &Error::Error("SD", MESSAGE => "Error updating record.2 $in{'DB'}->{'ERROR'}");
    
    goto END;
  }
  
  COOKMANUAL: if ($SD::COOKIES{'Username'} && $SD::COOKIES{'Password'}) {
    $Account = $in{'DB'}->BinarySelect(
      TABLE => "UserAccounts",
      KEY   => $SD::COOKIES{'Username'}
    );
    if ($Account && $Account->{'PASSWORD'} eq $SD::COOKIES{'Password'}) {
      $Session = {
        USERNAME      => $SD::COOKIES{'Username'},
        PASSWORD      => $SD::COOKIES{'Password'},
        IP            => $ENV{'REMOTE_ADDR'},
        LOGIN_SECOND  => time
      };
    
      (
        $Session->{'ID'} = $in{'DB'}->Insert(
          TABLE   => "Sessions",
          VALUES  => $Session
        )
      ) || &Error::Error("SD", MESSAGE => "Error inserting record. $in{'DB'}->{'ERROR'}");
    
      $SD::COOKIES{'SID'} = $Session->{'ID'};
      goto END;
    } else {
      $SD::COOKIES{'Username'} = "";
      $SD::COOKIES{'Password'} = "";
    }
  }
  
  return 1 unless ($in{'REQUIRE_AUTH'});
  
  require "Login.pm.pl";
  my $Source = Login->new();
     $Source->show(DB => $in{'DB'});
  exit;
  
END:
  $SD::USER{'ACCOUNT'} = $Account;
  $SD::USER{'SESSION'} = $Session;

  if ($SD::USER{'ACCOUNT'}->{'STATUS'} != 50) {
    &Error::Error("SD", MESSAGE => "Your account is inactive");
  }

  return 1;
}

1;