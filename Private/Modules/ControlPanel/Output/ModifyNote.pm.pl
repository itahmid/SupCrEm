###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/ModifyNote.pm.pl -> ModifyNote skin module               #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::ModifyNote;

BEGIN { require "System.pm.pl";  import System  qw($SYSTEM ); }
BEGIN { require "General.pm.pl"; import General qw($GENERAL); }
require "Standard.pm.pl";

use HTML::Dialog;
use HTML::Form;
use strict;

sub new {
  my ($class) = @_;
  my $self    = {};
  return bless ($self, $class);
}

sub DESTROY { }

###############################################################################
# show subroutine
sub show {
  my $self = shift;
  my %in = (input => undef, error => "", @_);

  my $LANGUAGE = {
    "MISSING" => {
      "SUBJECT" => qq~<li>You didn't fill in the "Subject" field.~,
      "MESSAGE" => qq~<li>You didn't fill in the "Message" field.~,
      "AUTHOR"  => qq~<li>You didn't fill in the "Author" field.~
    },
    "INVALID" => {
      "AUTHOR"  => qq~<li>The value you entered for the "Author" field is invalid.~
    },
    "TOOLONG" => {
      "SUBJECT" => qq~<li>The value for the "Subject" field must be 512 characters or less.~
    },
    "ERROR"   => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };

  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form   = HTML::Form->new();

  my $Body = $Dialog->Text(text => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:".$in{'error'});

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'NOTE'}->{'ID'},
    subject   => "ID"
  );
  
  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'NOTE'}->{'TID'},
    subject   => "Ticket ID"
  );

  $Body .= $Dialog->TextBox(
    name      => "FORM_SUBJECT",
    value     => $SD::QUERY{'FORM_SUBJECT'} || $in{'input'}->{'NOTE'}->{'SUBJECT'},
    subject   => "Subject",
    required  => 1
  );

  if ($in{'input'}->{'FIRST_NOTE'}) {
    $Body .= $Dialog->TextBox(
      value   => "--- Ticket Author ---",
      subject => "Author"
    );
  } else {
    my @options;
    push(@options, { value => "[TICKET-AUTHOR]", text => "--- Ticket Author ---" });
    if ($SD::ADMIN{'LEVEL'} == 100) {
      foreach my $staff (@{ $in{'input'}->{'STAFF_ACCOUNTS'} }) {
        push(@options, { value => $staff->{'USERNAME'}, text => $staff->{'NAME'}." (".$staff->{'USERNAME'}.")" });
      }
    } else {
      push(@options, { value => $SD::ADMIN{'USERNAME'}, text => $SD::ADMIN{'NAME'}." (".$SD::ADMIN{'USERNAME'}.")" });
    }
  
    $in{'input'}->{'NOTE'}->{'AUTHOR'} = "[TICKET-AUTHOR]" if ($in{'input'}->{'NOTE'}->{'AUTHOR_TYPE'} eq "USER");
    $Body .= $Dialog->SelectBox(
      name      => "FORM_AUTHOR",
      value     => $SD::QUERY{'FORM_AUTHOR'} || $in{'input'}->{'NOTE'}->{'AUTHOR'},
      subject   => "Author",
      required  => 1,
      options   => \@options,
      extra     => "onChange=\"ChangeAuthor()\""
    );
  }
  
  $Body .= $Dialog->TextArea(
    name      => "FORM_MESSAGE",
    value     => $SD::QUERY{'FORM_MESSAGE'} || $in{'input'}->{'NOTE'}->{'MESSAGE'},
    subject   => "Message",
    rows      => 10,
    required  => 1
  );

  my $Temp = $Dialog->SmallHeader(
    titles => [
      { text => "del", width => 1 },
      { text => "file", width => "100%" }
    ]
  );
  
  my @Attachments = split(/,/, $in{'input'}->{'NOTE'}->{'ATTACHMENTS'});
  if (scalar(@Attachments) >= 1) {
    foreach my $file (@Attachments) {
      my @fields;
      $fields[0] = $Form->CheckBox(
        checkboxes  => [
          { name  => "FORM_ATTACHMENT_DELETE", value => $file }
        ]
      );
      $fields[1] = qq~<a href="$SYSTEM->{'PUBLIC_URL'}/Attachments/$in{'input'}->{'NOTE'}->{'ID'}/$file">$file</a>~;
      $Temp .= $Dialog->Row(fields => \@fields);
    }
  } else {
    $Temp .= $Dialog->Row(fields => "Currently no attachments.", colspan => 2);
  }
  
  my $value  = qq~<table cellpadding="0" cellspacing="0" border="0" width="100%">~;
     $value .= qq~<tr>~;
     $value .= qq~<td width="1" nowrap><font class="row">Upload:</font></td>~;
     $value .= qq~<td width="5" nowrap></td>~;
     $value .= qq~<td width="100%"><input type="file" name="FORM_ATTACHMENT_UPLOAD" class="textbox"></td>~;
     $value .= qq~</tr>~;
     $value .= qq~</table>~;
  
  $Temp .= $Dialog->Row(fields => $value, colspan => 2);
  $Body .= $Dialog->TextBox(
    value       => qq~<table border="0" cellpadding="1" cellspacing="0" width="100%" class="border"><tr><td><table border="0" cellpadding="3" cellspacing="1" width="100%" class="body">$Temp</table></td></tr></table>~,
    subject     => "Attachments"
  );

  $Body .= $Dialog->CheckBox(
    name        => "FORM_PRIVATE",
    value       => $SD::QUERY{'FORM_PRIVATE'} || $in{'input'}->{'NOTE'}->{'PRIVATE'},
    checkboxes  => [{ value => "1", label => "Private?" }]
  );
  
  $Body .= $Dialog->Button(
    buttons => [
      { type => "submit", value => "Modify" },
      { type => "reset", value => "Cancel" }
    ], join => "&nbsp;"
  );

  my $Script = <<HTML;
<script language="JavaScript">
  <!--
  function ChangeAuthor() {
    var author = form.FORM_NOTE_AUTHOR;
    var private = form.FORM_NOTE_PRIVATE;
    
    if (author.value == "[TICKET-AUTHOR]") {
      private.checked = false;
      private.disabled = true;
    } else {
      private.disabled = false;
    }
  }
  //-->
</script>
HTML
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a note").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Script.$Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "NID", value => $SD::QUERY{'NID'} },
      { name => "CP", value => "1" },
      { name => "action", value => "DoModifyNote" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ],
    extra   => qq~enctype="multipart/form-data"~
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;
  my %in = (input => undef, @_);

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The following note has been modified:");

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'NOTE'}->{'ID'},
    subject   => "ID"
  );

  $Body .= $Dialog->TextBox(
    value     => $in{'input'}->{'NOTE'}->{'TID'},
    subject   => "Ticket ID"
  );

  $Body .= $Dialog->TextBox(
    value   => $in{'input'}->{'RECORD'}->{'SUBJECT'},
    subject => "Subject"
  );

  my $Value;
  if ($in{'input'}->{'RECORD'}->{'AUTHOR_TYPE'} eq "USER") {
    if ($in{'input'}->{'TICKET'}->{'AUTHOR'}) {
      $Value = $in{'input'}->{'USER_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'USER_ACCOUNT'}->{'USERNAME'}.")";
    } elsif ($in{'input'}->{'TICKET'}->{'GUEST_NAME'}) {
      $Value = $in{'input'}->{'TICKET'}->{'GUEST_NAME'}." (".$in{'input'}->{'TICKET'}->{'EMAIL'}.")";
    } else {
      $Value = $in{'input'}->{'TICKET'}->{'EMAIL'};
    }
  } else {
    $Value = $in{'input'}->{'STAFF_ACCOUNT'}->{'NAME'}." (".$in{'input'}->{'STAFF_ACCOUNT'}->{'USERNAME'}.")";
  }
  $Body .= $Dialog->TextBox(
    value   => $Value,
    subject => "Author"
  );

  $in{'input'}->{'RECORD'}->{'MESSAGE'} = &Standard::HTMLize($in{'input'}->{'RECORD'}->{'MESSAGE'});
  $in{'input'}->{'RECORD'}->{'MESSAGE'} =~ s/\n/<br>/g;
  $Body .= $Dialog->TextArea(
    value   => $in{'input'}->{'RECORD'}->{'MESSAGE'},
    subject => "Message"
  );
  
  $Body .= $Dialog->TextBox(
    value   => join("<br>", split(/,/, $in{'input'}->{'RECORD'}->{'ATTACHMENTS'})),
    subject => "Attachments"
  );
  
  $Body = $Dialog->Dialog(body => $Body);
  $Body = $Dialog->SmallHeader(titles => "modify a note").$Body;
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;