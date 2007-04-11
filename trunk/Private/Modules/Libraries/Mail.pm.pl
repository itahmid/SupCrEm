###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Mail.pm.pl -> Mail library                                                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Mail;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }

sub new {
  my ($class) = @_;
  my $self    = {};
  
  eval "use MIME::QuotedPrint";
  $self->{'NO_ATTACH'} = 1 if ($@);
  eval "use MIME::Base64";
  $self->{'NO_ATTACH'} = 1 if ($@);
  
  return bless ($self, $class);
}

sub DESTROY {}

###############################################################################
# Send subroutine
sub Send {
  my $self = shift;
  my %in = ("TO" => "", @_);

  $self->{'ERROR'} = "No recipient" and return if (!$in{'TO'});

  if ($in{'ATTACHMENTS'} && !$self->{'NO_ATTACH'}) {
    my $contenttype = $in{'HEADERS'}->{'Content-Type'} || "text/html; charset=\"iso-8859-1\"";
    
    my $boundary = "====".time()."====";
    $in{'HEADERS'}->{'Content-Type'} = "multipart/mixed; boundary=\"$boundary\"";
    $boundary = "--".$boundary;

    my $message = encode_qp($in{'MESSAGE'});
    
    $in{'MESSAGE'} = <<TEXT;
$boundary
$contenttype
Content-Transfer-Encoding: quoted-printable

$message
TEXT

    foreach my $file (@{ $in{'ATTACHMENTS'} }) {
      open(FILE, $file);
      binmode(FILE);
      undef($/);
      my $attachment = encode_base64(<FILE>);
      close(FILE);
    
      my @file = split(/(\\|\/)/, $file);
      my $filename = $file[$#file];
    
      $in{'MESSAGE'} .= <<TEXT;
$boundary
Content-Type: application/octet-stream; name="$filename"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="$filename"

$attachment
TEXT
    }
    
    $in{'MESSAGE'} .= $boundary."--\n";
  }

  if ($SYSTEM->{'MAIL_TYPE'} eq "SENDMAIL") {
    $self->Sendmail(%in) and return 1;
  } else {
    $self->SMTP(%in) and return 1;
  }
}

###############################################################################
# Sendmail subroutine (internal)
sub Sendmail {
  my $self = shift;
  my %in = (
    "TO"      => "",
    "FROM"    => "$GENERAL->{'DESK_TITLE'} <$GENERAL->{'CONTACT_EMAIL'}>",
    "CC"      => "",
    "BCC"     => "",
    "SUBJECT" => "",
    "HEADERS" => {
      "Content-Type"  => "text/html; charset=\"iso-8859-1\""
    },
    "MESSAGE" => "",
    @_
  );

  # Filter inputs
  $in{'TO'}  =~ s/[ \t]+/ /g;
  $in{'CC'}  =~ s/[ \t]+/ /g;
  $in{'BCC'} =~ s/[ \t]+/ /g;

  $in{'TO'}  =~ s/,,/,/g;
  $in{'CC'}  =~ s/,,/,/g;
  $in{'BCC'} =~ s/,,/,/g;

  # Send email
  open(MAIL, "|$SYSTEM->{'SENDMAIL'} -t") || ($self->{'ERROR'} = $! and return);
  print MAIL "To: $in{'TO'}\n";
  print MAIL "From: $in{'FROM'}\n";
  print MAIL "Bcc: $in{'BCC'}\n" if $in{'BCC'};
  print MAIL "Cc: $in{'CC'}\n" if $in{'CC'};

  foreach $Key (keys %{ $in{'HEADERS'} }) {
    print MAIL $Key . ": " . $in{'HEADERS'}{$Key} . "\n" if $in{'HEADERS'}{$Key};
  }

  print MAIL "X-Mailer: SuperDesk\n";
  print MAIL "X-Mailer-Info: http://www.obsidian-scripts\n";
  print MAIL "Subject: $in{'SUBJECT'}\n" if $in{'SUBJECT'};
  print MAIL "\n";
  print MAIL "$in{'MESSAGE'}\n\n" if $in{'MESSAGE'};
  close(MAIL);

  return 1;
}

###############################################################################
# SMTP subroutine (internal)
sub SMTP {
  my $self = shift;
  my %in = (
    "TO"      => "",
    "FROM"    => "$GENERAL->{'DESK_TITLE'} <$GENERAL->{'CONTACT_EMAIL'}>",
    "CC"      => "",
    "BCC"     => "",
    "SUBJECT" => "",
    "HEADERS" => {
      "Content-Type"  => "text/html; charset=\"iso-8859-1\""
    },
    "MESSAGE" => "",
    @_
  );

  use Mail::Sendmail;

  unshift(@{ $Mail::Sendmail::mailcfg{'smtp'} }, $SYSTEM->{'SMTP_SERVER'});

  my %Mail;
  
  $Mail{'To'}             = $in{'TO'};
  $Mail{'From'}           = $in{'FROM'};
  $Mail{'Cc'}             = $in{'CC'} if ($in{'CC'});
  $Mail{'Bcc'}            = $in{'BCC'} if ($in{'BCC'});
  $Mail{'Subject'}        = $in{'SUBJECT'};
  
  foreach my $key (keys %{ $in{'HEADERS'} }) {
    $Mail{ $key } = $in{'HEADERS'}->{ $key };
  }
  
  $Mail{'X-Mailer'}       = "SuperDesk";
  $Mail{'X-Mailer-Info'}  = "http://www.obsidian-scripts.com/?tag=SuperDesk";
  
  if ($in{'ATTACHMENTS'} && !$self->{'NO_ATTACH'}) {
    $Mail{'Body'} = $in{'MESSAGE'};
  } else {
    $Mail{'Message'} = $in{'MESSAGE'};
  }

  &sendmail(%Mail) || ($self->{'ERROR'} = $Mail::Sendmail::error and return);

  return 1;
}

1;