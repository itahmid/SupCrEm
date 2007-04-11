###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# ControlPanel/GeneralOptions.pm.pl -> GeneralOptions module                  #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package CP::GeneralOptions;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Error.pm.pl";
require "Standard.pm.pl";
require "Authenticate.pm.pl";
require "Variables.pm.pl";

use strict;

require "ControlPanel/Output/GeneralOptions.pm.pl";

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
  # Getting data...                                                      #

  my @Skins;
  
  opendir(DIR, "$SD::PATH/Private/Skins") || &Error::CGIError("Error opening directory for reading. $!", "$SD::PATH/Private/Skins");
  foreach my $file (grep(/\.cfg$/, readdir(DIR))) {
    my $id = $file;
       $id =~ s/\.cfg$//;
    
    &Standard::FileOpen(*CFG, "r", "$SD::PATH/Private/Skins/$file");
    push(@Skins, { ID => $id, DESCRIPTION => join("", <CFG>) });
    close(CFG);
  }
  closedir(DIR);

  my ($Categories, $CategoriesIndex) = $in{'DB'}->Query(
    TABLE   => "Categories",
    SORT    => "NAME",
    BY      => "A-Z"
  );

  my %INPUT;
  
  $INPUT{'SKINS'} = \@Skins;
  $INPUT{'CATEGORIES'} = $Categories;
  $INPUT{'CATEGORIES_IX'} = $CategoriesIndex;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::GeneralOptions->new();

  &Standard::PrintHTMLHeader();
  print $Skin->show(input => \%INPUT, error => $in{'ERROR'});
  
  return 1;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (DB => undef, @_);

  #----------------------------------------------------------------------#
  # Authenticating...                                                    #
  
  &Authenticate::CP(DB => $in{'DB'});

  #----------------------------------------------------------------------#
  # Checking fields...                                                   #

  my @Fields = (  
    { name => "SITE_TITLE"                , required => 1, type => "scalar" },
    { name => "SITE_URL"                  , required => 1, type => "scalar" },
    { name => "DESK_TITLE"                , required => 1, type => "scalar" },
    { name => "DESK_DESCRIPTION"          , required => 1, type => "scalar" },
    { name => "CONTACT_EMAIL"             , required => 1, type => "scalar" },
    { name => "ADMIN_EMAIL"               , required => 0, type => "scalar" },
    { name => "SKIN"                      , required => 1, type => "scalar" },
    { name => "MAIL_FUNCTIONS"            , required => 1, type => "scalar" },
    { name => "NOTIFY_USER_OF_TICKET"     , required => 1, type => "scalar" },
    { name => "NOTIFY_USER_OF_NOTE"       , required => 1, type => "scalar" },
    { name => "REQUIRE_REGISTRATION"      , required => 1, type => "scalar" },
    { name => "HTML_IN_ADMIN_EMAILS"      , required => 1, type => "scalar" },
    { name => "HTML_IN_USER_EMAILS"       , required => 1, type => "scalar" },
    { name => "DATE_FORMAT"               , required => 1, type => "scalar" },
    { name => "TIME_FORMAT"               , required => 1, type => "scalar" },
    { name => "ALLOW_SUPPORT_CREATE_USERS", required => 1, type => "scalar" },
    { name => "ALLOW_SUPPORT_MODIFY_USERS", required => 1, type => "scalar" },
    { name => "ALLOW_SUPPORT_REMOVE_USERS", required => 1, type => "scalar" },
    { name => "DEFAULT_PRIORITY"          , required => 1, type => "scalar" },
    { name => "DEFAULT_SEVERITY"          , required => 1, type => "scalar" },
    { name => "DEFAULT_STATUS"            , required => 1, type => "scalar" },
    { name => "USER_LEVELS"               , required => 1, type => "fixedhash(30,40,50,60)" },
    { name => "PRIORITIES"                , required => 1, type => "fixedhash(30,40,50,60)" },
    { name => "SEVERITIES",               , required => 1, type => "fixedhash(30,40,50,60)" },
    { name => "STATUS",                   , required => 1, type => "fixedhash(30,40,50,60,70)" },
    { name => "EMAIL_ADDRESSES"           , required => 0, type => "hash"   },
    { name => "SAVE_HTML_ATTACHMENTS"     , required => 1, type => "scalar" },
    { name => "SAVE_OTHER_ATTACHMENTS"    , required => 1, type => "scalar" },
    { name => "USER_ATTACHMENTS"          , required => 1, type => "scalar" },
    { name => "ATTACHMENT_EXTS"           , required => 1, type => "array"  },
    { name => "MAX_ATTACHMENT_SIZE"       , required => 1, type => "scalar" },
    { name => "SHOW_HTML_MESSAGE"         , required => 1, type => "scalar" },
    { name => "REMOVE_ORIGINAL_MESSAGE"   , required => 1, type => "scalar" },
    { name => "TICKETS_PER_PAGE"          , required => 1, type => "scalar" }
  );

  my (%RECORD, @Error);

  foreach my $field (@Fields) {
    if ($field->{'type'} eq "scalar" || $field->{'type'} eq "array" || $field->{'type'} eq "hash") {
      if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}} eq "") {
        push(@Error, "MISSING-".$field->{'name'});
      } elsif ($field->{'type'} eq "array") {
        @{ $RECORD{$field->{'name'}} } = split(/\|/, $SD::QUERY{'FORM_'.$field->{'name'}});
      } elsif ($field->{'type'} eq "hash") {
        my @array = $SD::CGI->param('FORM_'.$field->{'name'});
        foreach my $item (@array) {
          my ($key, $value) = split(/::/, $item);
          $RECORD{$field->{'name'}}->{$key} = $value;
        }
      } else {
        $RECORD{ $field->{'name'} } = $SD::QUERY{'FORM_'.$field->{'name'}};
      }
    } elsif ($field->{'type'} =~ /^fixedhash\((.*)\)$/) {
      my $keys = $1; my @keys = split(/,/, $keys);
      foreach my $key (@keys) {
        if ($field->{'required'} && $SD::QUERY{'FORM_'.$field->{'name'}."_".$key} eq "") {
          push(@Error, "MISSING-".$field->{'name'});
          last;
        } else {
          $RECORD{$field->{'name'}}->{$key} = $SD::QUERY{'FORM_'.$field->{'name'}."_".$key};
        }
      }
    }
  }

  if (scalar(@Error) >= 1) {
    $self->show(DB => $in{'DB'}, ERROR => \@Error);
    return 1;
  }

  #----------------------------------------------------------------------#
  # Updating data...                                                     #

  my $Variables = Variables->new();
  
  $Variables->Update(
    FILE      => "$SD::PATH/Private/Variables/General.pm.pl",
    PACKAGE   => "General",
    VARIABLE  => "GENERAL",
    VALUES    => \%RECORD
  ) || &Error::Error("CP", MESSAGE => "Error updating variable file. $Variables->{'ERROR'}", "$SD::PATH/Private/Variables/General.pm.pl");
  
  my %INPUT;
  
  $INPUT{'RECORD'} = \%RECORD;
  
  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Skin = Skin::CP::GeneralOptions->new();

  &Standard::PrintHTMLHeader();
  print $Skin->do(input => \%INPUT);
  
  return 1;
}

1;