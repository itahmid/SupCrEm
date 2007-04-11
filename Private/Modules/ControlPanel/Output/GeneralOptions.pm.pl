###############################################################################
# SuperDesk                                                                   #
# Written by Gregory Nolle (greg@nolle.co.uk)                                 #
# Copyright 2002 by PlasmaPulse Solutions (http://www.plasmapulse.com)        #
###############################################################################
# Skins/ControlPanel/GeneralOptions.pm.pl -> GeneralOptions skin module       #
###############################################################################
# DON'T EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING!                         #
###############################################################################
package Skin::CP::GeneralOptions;

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

  my @Sections = (
    { title => "General Information", items => [
      { subject => "Please fill out all the required (<font color=\"Red\"><b>*</b></font>) fields:", type => "text" },
      { name => "SITE_TITLE", subject => "Web Site Name", type => "textbox", required => 1, iconhelp => "The title of your web site." },
      { name => "SITE_URL", subject => "Web Site URL", type => "textbox", required => 1, iconhelp => "The full URL of your web site." },
      { name => "DESK_TITLE", subject => "Help Desk Name", type => "textbox", required => 1, iconhelp => "The title of your Help Desk system." },
      { name => "DESK_DESCRIPTION", subject => "Help Desk Description", type => "textbox", required => 1, iconhelp => "The description or catch-phrase of your Help Desk sytem (appears at the top of every page)." },
      { name => "CONTACT_EMAIL", subject => "Contact Email", type => "textbox", required => 1, iconhelp => "The email address you want used in emails sent by the Help Desk, that aren't associated with a particular category." }
    ]},
    { title => "Mail Options", items => [
      { name => "MAIL_FUNCTIONS", subject => "Mail Functions", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable email functions, such as notification of additions, modifications, etc. Individual functions can be enabled/disabled below." },
      { name => "NOTIFY_USER_OF_TICKET", subject => "Notify Users of Tickets", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable emails sent to users after they submit a ticket." },
      { name => "NOTIFY_USER_OF_NOTE", subject => "Notify Users of Notes", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable emails sent to users after they add a note to a ticket." },
      { name => "HTML_IN_ADMIN_EMAILS", subject => "HTML in Emails to Admin", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable HTML in emails sent to the administrator." },
      { name => "HTML_IN_USER_EMAILS", subject => "HTML in Emails to User", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable HTML in emails sent to users." }
    ]},
    { title => "Date & Time Options", items => [
      { name => "DATE_FORMAT", subject => "Date Format", type => "dateformat", required => 1, iconhelp => "The format dates should appear in." },
      { name => "TIME_FORMAT", subject => "Time Format", type => "timeformat", required => 1, iconhelp => "The format times should appear in." }
    ]},
    { title => "Support Staff Priviledges", items => [
      { name => "ALLOW_SUPPORT_CREATE_USERS", subject => "Allow User Creation", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Allow Support Staff to create user accounts." },
      { name => "ALLOW_SUPPORT_MODIFY_USERS", subject => "Allow User Modification", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Allow Support Staff to modify user accounts." },
      { name => "ALLOW_SUPPORT_REMOVE_USERS", subject => "Allow User Removal", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Allow Support Staff to remove user accounts." }
    ]},
    { title => "Default Ticket Options", items => [
      { name => "DEFAULT_PRIORITY", subject => "Default Priority", type => "selectbox(30[$GENERAL->{'PRIORITIES'}->{'30'}],40[$GENERAL->{'PRIORITIES'}->{'40'}],50[$GENERAL->{'PRIORITIES'}->{'50'}],60[$GENERAL->{'PRIORITIES'}->{'60'}])", required => 1, iconhelp => "The default priority of a new ticket." },
      { name => "DEFAULT_SEVERITY", subject => "Default Severity", type => "selectbox(30[$GENERAL->{'SEVERITIES'}->{'30'}],40[$GENERAL->{'SEVERITIES'}->{'40'}],50[$GENERAL->{'SEVERITIES'}->{'50'}],60[$GENERAL->{'SEVERITIES'}->{'60'}])", required => 1, iconhelp => "The default severity of a new ticket." },
      { name => "DEFAULT_STATUS", subject => "Default Status", type => "selectbox(30[$GENERAL->{'STATUS'}->{'30'}],40[$GENERAL->{'STATUS'}->{'40'}],50[$GENERAL->{'STATUS'}->{'50'}],60[$GENERAL->{'STATUS'}->{'60'}],70[$GENERAL->{'STATUS'}->{'70'}])", required => 1, iconhelp => "The default status of a new ticket." }
    ]},
    { title => "User Levels", items => [
      { name => "USER_LEVELS_30", subject => "Level 30 Description", type => "fixedhash(USER_LEVELS)", required => 1, iconhelp => "The description of the User Level 30." },
      { name => "USER_LEVELS_40", subject => "Level 40 Description", type => "fixedhash(USER_LEVELS)", required => 1, iconhelp => "The description of the User Level 40." },
      { name => "USER_LEVELS_50", subject => "Level 50 Description", type => "fixedhash(USER_LEVELS)", required => 1, iconhelp => "The description of the User Level 50." },
      { name => "USER_LEVELS_60", subject => "Level 60 Description", type => "fixedhash(USER_LEVELS)", required => 1, iconhelp => "The description of the User Level 60." }
    ]},
    { title => "Priorities", items => [
      { name => "PRIORITIES_30", subject => "Priority 30 Description", type => "fixedhash(PRIORITIES)", required => 1, iconhelp => "The description of the Priority 30." },
      { name => "PRIORITIES_40", subject => "Priority 40 Description", type => "fixedhash(PRIORITIES)", required => 1, iconhelp => "The description of the Priority 40." },
      { name => "PRIORITIES_50", subject => "Priority 50 Description", type => "fixedhash(PRIORITIES)", required => 1, iconhelp => "The description of the Priority 50." },
      { name => "PRIORITIES_60", subject => "Priority 60 Description", type => "fixedhash(PRIORITIES)", required => 1, iconhelp => "The description of the Priority 60." }
    ]},
    { title => "Severities", items => [
      { name => "SEVERITIES_30", subject => "Severity 30 Description", type => "fixedhash(SEVERITIES)", required => 1, iconhelp => "The description of the Severity 30." },
      { name => "SEVERITIES_40", subject => "Severity 40 Description", type => "fixedhash(SEVERITIES)", required => 1, iconhelp => "The description of the Severity 40." },
      { name => "SEVERITIES_50", subject => "Severity 50 Description", type => "fixedhash(SEVERITIES)", required => 1, iconhelp => "The description of the Severity 50." },
      { name => "SEVERITIES_60", subject => "Severity 60 Description", type => "fixedhash(SEVERITIES)", required => 1, iconhelp => "The description of the Severity 60." }
    ]},
    { title => "Statuses", items => [
      { name => "STATUS_30", subject => "Status 30 Description", type => "fixedhash(STATUS)", required => 1, iconhelp => "The description of the Status 30." },
      { name => "STATUS_40", subject => "Status 40 Description", type => "fixedhash(STATUS)", required => 1, iconhelp => "The description of the Status 40." },
      { name => "STATUS_50", subject => "Status 50 Description", type => "fixedhash(STATUS)", required => 1, iconhelp => "The description of the Status 50." },
      { name => "STATUS_60", subject => "Status 60 Description", type => "fixedhash(STATUS)", required => 1, iconhelp => "The description of the Status 60." },
      { name => "STATUS_70", subject => "Status 70 Description", type => "fixedhash(STATUS)", required => 1, iconhelp => "The description of the Status 70." }
    ]},
    { title => "Attachments", items => [
      { name => "SAVE_HTML_ATTACHMENTS", subject => "Save HTML Message As Attachment", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable whether the HTML form of emails (if available) is saved as an attachment." },
      { name => "SAVE_OTHER_ATTACHMENTS", subject => "Save Other Attachments", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable whether email attachments will be saved." },
      { name => "USER_ATTACHMENTS", subject => "Allow User Control Panel Attachments", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable whether attachments in the users' control panel are permitted." },
      { name => "ATTACHMENT_EXTS", subject => "Attachment Extensions", type => "array", required => 1, iconhelp => "Only files with one of these extensions will be accepted as user attachments either via email or the User Control Panel." },
      { name => "MAX_ATTACHMENT_SIZE", subject => "Maximum Attachment Size (KB)", type => "textbox", required => 1, iconhelp => "Maximum file size, in kilobytes, allowed for user attachments (1 MB = 1024 KB)" },
      { name => "SHOW_HTML_MESSAGE", subject => "Show HTML Message", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable whether the HTML form of a note (if available) is displayed in the user and staff control panels." }
    ]},
    { title => "Misc. Options", items => [
      { name => "EMAIL_ADDRESSES", subject => "Email Address Mappings", type => "addresses", required => 0, iconhelp => "Map email addresses assigned to the Help Desk to categories." },
      { name => "SKIN", subject => "Default Skin", type => "skin", required => 1, iconhelp => "The default skin to use when displaying pages. This can be overided on a individual basis by appending ?Skin=xxx to a URL." },
      { name => "REQUIRE_REGISTRATION", subject => "Require Registration", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable the requirement for users to be registered before they can submit tickets and notes to the Help Desk." },
      { name => "REMOVE_ORIGINAL_MESSAGE", subject => "Remove Quoted Original Message", type => "radio(1[Enable],0[Disable])", required => 1, iconhelp => "Enable/disable whether original quoted messages in emails (i.e. lines below the '--- Original Message ---' line) will be removed. This will only happen if, after removal, there is still a non-blank message." },
      { name => "TICKETS_PER_PAGE", subject => "Default Tickets Per Page", type => "textbox", required => 1, iconhelp => "The default number of tickets to show per page in the Control Panel." },
      { type => "buttons" }
    ]}
  );

  my $LANGUAGE = {
    "MISSING" => { },
    "ERROR"   => qq~<p><font class="error-body">There were errors:<ul>[%error%]</ul></font>~
  };
  
  foreach my $section (@Sections) {
    foreach my $item (@{ $section->{'items'} }) {
      $LANGUAGE->{'MISSING'}->{ $item->{'name'} } = qq~<li>You didn't fill in the "$item->{'subject'}" field.~ if ($item->{'subject'});
    }
  }
  
  $in{'error'} = &Standard::ProcessError(LANGUAGE => $LANGUAGE, ERROR => $in{'error'});
  $Sections[0]->{'items'}->[0]->{'subject'} .= $in{'error'};

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();
  my $Form = HTML::Form->new();

  my $Body = $Dialog->SmallHeader(titles => "general options");
  
  foreach my $section (@Sections) {
    $Body .= $Dialog->LargeHeader(title => $section->{'title'}) if ($section->{'title'});
    
    my $Temp;
    foreach my $item (@{ $section->{'items'} }) {
      if ($item->{'type'} eq "textbox") {
        $Temp .= $Dialog->TextBox(
          name      => ($item->{'locked'} ? "" : "FORM_".$item->{'name'}),
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$item->{'name'}},
          subject   => $item->{'subject'},
          help      => $item->{'help'},
          required  => $item->{'required'},
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} =~ /^fixedhash\((.*)\)$/) {
        my $hash = $1;
        my $metahash = $hash."_";
        $item->{'name'} =~ m/^$metahash(.*)$/;
        $Temp .= $Dialog->TextBox(
          name      => ($item->{'locked'} ? "" : "FORM_".$item->{'name'}),
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$hash}->{$1},
          subject   => $item->{'subject'},
          help      => $item->{'help'},
          required  => $item->{'required'},
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} eq "addresses") {
        my $script .= <<HTML;
<script language="JavaScript">
  <!--
  function $item->{'name'}_AddOption(form) {
    var key = form.KEY_$item->{'name'};
    var value = form.VALUE_$item->{'name'}.options[form.VALUE_$item->{'name'}.selectedIndex];
    var sel = form.FORM_$item->{'name'};
    
    if (key.value != "" && value.value != "") {
      sel.options[sel.options.length] = new Option("\\"" + key.value + "\\" => \\"" + value.text + "\\"", key.value + "::" + value.value);
      key.value = "";
    }
  }
  function $item->{'name'}_Select(form) {
    var sel = form.FORM_$item->{'name'};
    var del = form.DelButton;
    var edit = form.EditButton;

    var numsel = 0;
    for (var h = 0; h < sel.options.length; h++) {
      var current = sel.options[h];
      if (current.selected) {
        numsel++;
      }
    }

    if (numsel == 1) {
      del.disabled = 0;
      edit.disabled = 0;
    } else {
      del.disabled = 1;
      edit.disabled = 1;
    }
  }
  function $item->{'name'}_DelOption(form) {
    var sel = form.FORM_$item->{'name'};
    var del = form.DelButton;
    var edit = form.EditButton;
    
    var numsel = 0;
    for (var h = 0; h < sel.options.length; h++) {
      var current = sel.options[h];
      if (current.selected) {
        numsel++;
      }
    }
    
    if (numsel == 1) {
      sel.options[sel.options.selectedIndex] = null;
      del.disabled = 1;
      edit.disabled = 1;
    }
  }
  function $item->{'name'}_EditOption(form) {
    var sel = form.FORM_$item->{'name'};
    var del = form.DelButton;
    var edit = form.EditButton;

    var key = form.KEY_$item->{'name'};
    var value = form.VALUE_$item->{'name'};
    
    var numsel = 0;
    for (var h = 0; h < sel.options.length; h++) {
      var current = sel.options[h];
      if (current.selected) {
        numsel++;
      }
    }
    
    if (numsel == 1) {
      var option = sel.options[sel.options.selectedIndex].value.split("::");
      key.value = option[0];
      
      for (var h = 0; h < value.options.length; h++) {
        var current = value.options[h];
        if (current.value == option[1]) {
          current.selected = 1;
        }
      }
      
      sel.options[sel.options.selectedIndex] = null;
      del.disabled = 1;
      edit.disabled = 1;
    }
  }
  function formSubmit() {
    var sel = form.FORM_$item->{'name'};
    
    for (var h = 0; h < sel.options.length; h++) {
      var current = sel.options[h];
      current.selected = 1;
    }
    
    return true;
  }
  //-->
</script>
HTML

        my @options;
        if (my @value = $SD::CGI->param('FORM_'.$item->{'name'})) {
          foreach my $value (@value) {
            my ($email, $category) = split(/::/, $value);
            $category = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$category}]->{'NAME'};
            push(@options, { value => $value, text => "\"".$email."\" => \"".$category."\"" });
          }
        } else {        
          foreach my $key (keys %{ $GENERAL->{'EMAIL_ADDRESSES'} }) {
            my $category = $in{'input'}->{'CATEGORIES'}->[$in{'input'}->{'CATEGORIES_IX'}->{$GENERAL->{'EMAIL_ADDRESSES'}->{$key}}]->{'NAME'};
            push(@options, { value => $key."::".$GENERAL->{'EMAIL_ADDRESSES'}->{$key}, text => "\"".$key."\" => \"".$category."\"" });
          }
        }

        my $field  = qq~<table cellpadding="0" cellspacing="0" border="0" width="100%">~;
           $field .= qq~<tr><td colspan="5">~;
        
        $field .= $Form->SelectBox(
          name      => "FORM_".$item->{'name'},
          size      => 4,
          multiple  => 1,
          extra     => "onChange=\"$item->{'name'}_Select(form)\"",
          options   => \@options
        );
        
        $field .= qq~</td></tr>~;
        $field .= qq~<tr><td height="2"></td></tr>~;
        $field .= qq~<tr><td width="50%">~;
        $field .= $Form->TextBox(name => "KEY_".$item->{'name'});
        $field .= qq~</td><td width="1" nowrap>&nbsp;=&gt;&nbsp;</td><td width="50%">~;

        @options = ();
        foreach my $category (@{ $in{'input'}->{'CATEGORIES'} }) {
          push(@options, { value => $category->{'ID'}, text => $category->{'NAME'} });
        }
        
        $field .= $Form->SelectBox(
          name    => "VALUE_".$item->{'name'},
          options => \@options
        );

        $field .= qq~</td><td width="5" nowrap></td><td width="1%" nowrap>~;
        $field .= $Form->Button(
          buttons => [
            { type => "button", name => "AddButton", value => "Add", extra => "onClick=\"$item->{'name'}_AddOption(form)\"" },
            { type => "button", name => "DelButton", value => "Del", extra => "onClick=\"$item->{'name'}_DelOption(form)\" disabled" },
            { type => "button", name => "EditButton", value => "Edit", extra => "onClick=\"$item->{'name'}_EditOption(form)\" disabled" }
          ], join => "&nbsp;"
        );
        $field .= qq~</td></tr></table>~.$script;

        $Temp .= $Dialog->TextBox(
          value     => $field,
          subject   => $item->{'subject'},
          help      => $item->{'help'},
          iconhelp  => $item->{'iconhelp'},
          required  => $item->{'required'}
        );

      } elsif ($item->{'type'} eq "array") {
        my $script = <<HTML;
<script language="JavaScript">
  <!--
  function $item->{'name'}_AddOption(f) {
    var filter = f.FORM_$item->{'name'};
    var item = f.ITEM_$item->{'name'};

    if (item.value != "") {
      if (filter.value != "") {
        filter.value = filter.value + "|" + item.value;
      } else {
        filter.value = item.value;
      }
    }
    item.value = "";
  }
  //-->
</script>
HTML

        my $subfield  = qq~<table cellpadding="0" cellspacing="0" border="0" width="100%">~;
           $subfield .= qq~<tr><td width="100%">~;
           $subfield .= $Form->TextBox(name => "ITEM_".$item->{'name'});
           $subfield .= qq~</td><td width="5" nowrap></td><td width="1" nowrap>~;
           $subfield .= $Form->Button(buttons => [{ type => "button", value => "Add", extra => "onClick=\"$item->{'name'}_AddOption(form)\"" }]);
           $subfield .= qq~</td></tr></table>~.$script;

        $Temp .= $Dialog->TextArea(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || join("|", @{$GENERAL->{$item->{'name'}}}),
          subject   => $item->{'subject'},
          help      => $item->{'help'},
          iconhelp  => $item->{'iconhelp'},
          rows      => 3,
          required  => $item->{'required'},
          "sub-field" => $subfield
        );        
      } elsif ($item->{'type'} =~ /^radio\((.*)\)$/) {
        my $radios = $1;
        my @radios = split(/,/, $radios);
        foreach my $radio (@radios) {
          $radio =~ m/^(.*)\[(.*)\]$/;
          $radio = { value => $1, label => $2 };
        }
        $Temp .= $Dialog->Radio(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$item->{'name'}},
          subject   => $item->{'subject'},
          help      => $item->{'help'},
          required  => $item->{'required'},
          radios    => \@radios,
          join      => "&nbsp;",
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} =~ /^selectbox\((.*)\)$/) {
        my $options = $1;
        my @options = split(/,/, $options);
        foreach my $option (@options) {
          $option =~ m/^(.*)\[(.*)\]$/;
          $option = { value => $1, text => $2 };
        }
        $Temp .= $Dialog->SelectBox(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$item->{'name'}},
          subject   => $item->{'subject'},
          help      => $item->{'help'},
          required  => $item->{'required'},
          options   => \@options,
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} eq "text") {
        $Temp .= $Dialog->Text(text => $item->{'subject'});
      } elsif ($item->{'type'} eq "buttons") {
        $Temp .= $Dialog->Button(
          buttons => [
            { type => "submit", value => "Modify" },
            { type => "reset", value => "Cancel" }
          ], join => "&nbsp;"
        );
      } elsif ($item->{'type'} eq "skin") {
        my @options;
        foreach my $skin (@{ $in{'input'}->{'SKINS'} }) {
          push(@options, { value => $skin->{'ID'}, text => $skin->{'DESCRIPTION'} });
        }
        $Temp .= $Dialog->SelectBox(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          options   => \@options,
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} eq "dateformat") {
        my @radios = (
          { value => "US", label => "US Format (MM-DD-YYYY)" },
          { value => "USE", label => "Expanded US Format (Month DD, YYYY)" },
          { value => "EU", label => "European Format (DD-MM-YYYY)" },
          { value => "EUE", label => "Expanded European Format (DD Month, YYYY)" }
        );
        $Temp .= $Dialog->Radio(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          radios    => \@radios,
          join      => "<br>",
          iconhelp  => $item->{'iconhelp'}
        );
      } elsif ($item->{'type'} eq "timeformat") {
        my @radios = (
          { value => "24", label => "24 Hour Time Format" },
          { value => "12", label => "AM/PM 12 Hour Time Format" }
        );
        $Temp .= $Dialog->Radio(
          name      => "FORM_".$item->{'name'},
          value     => $SD::QUERY{'FORM_'.$item->{'name'}} || $GENERAL->{$item->{'name'}},
          subject   => $item->{'subject'},
          required  => $item->{'required'},
          radios    => \@radios,
          join      => "<br>",
          iconhelp  => $item->{'iconhelp'}
        );
      }      
    }
    
    $Body .= $Dialog->Dialog(body => $Temp);
  }
  
  $Body = $Dialog->Body($Body);
  $Body = $Dialog->Form(
    body    => $Body,
    hiddens => [
      { name => "action", value => "DoGeneralOptions" },
      { name => "CP", value => "1" },
      { name => "Username", value => $SD::ADMIN{'USERNAME'} },
      { name => "Password", value => $SD::ADMIN{'PASSWORD'} }
    ],
    extra   => "onSubmit=\"formSubmit()\""
  );
  $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

###############################################################################
# do subroutine
sub do {
  my $self = shift;

  #----------------------------------------------------------------------#
  # Printing page...                                                     #

  my $Dialog = HTML::Dialog->new();

  my $Body = $Dialog->Text(text => "The general options have been updated.");
     $Body = $Dialog->Dialog(body => $Body);
  
     $Body = $Dialog->SmallHeader(titles => "general options").$Body;
     
     $Body = $Dialog->Body($Body);
     $Body = $Dialog->Page(body => $Body);
  
  return $Body;
}

1;