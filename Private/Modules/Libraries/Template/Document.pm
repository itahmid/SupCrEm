##============================================================= -*-Perl-*-
#
# Template::Document
#
# DESCRIPTION
#   Module defining a class of objects which encapsulate compiled
#   templates, storing additional block definitions and metadata 
#   as well as the compiled Perl sub-routine representing the main
#   template content.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
# 
#----------------------------------------------------------------------------
#
# $Id: Document.pm,v 2.49 2002/04/17 14:04:38 abw Exp $
#
#============================================================================

package Template::Document;

require 5.004;

use strict;
use vars qw( $VERSION $ERROR $COMPERR $DEBUG $AUTOLOAD );
use base qw( Template::Base );
use Template::Constants;
use Fcntl qw(O_WRONLY O_CREAT O_TRUNC);

$VERSION = sprintf("%d.%02d", q$Revision: 2.49 $ =~ /(\d+)\.(\d+)/);


#========================================================================
#                     -----  PUBLIC METHODS -----
#========================================================================

#------------------------------------------------------------------------
# new(\%document)
#
# Creates a new self-contained Template::Document object which 
# encapsulates a compiled Perl sub-routine, $block, any additional 
# BLOCKs defined within the document ($defblocks, also Perl sub-routines)
# and additional $metadata about the document.
#------------------------------------------------------------------------

sub new {
    my ($class, $doc) = @_;
    my ($block, $defblocks, $metadata) = @$doc{ qw( BLOCK DEFBLOCKS METADATA ) };
    $defblocks ||= { };
    $metadata  ||= { };

    # evaluate Perl code in $block to create sub-routine reference if necessary
    unless (ref $block) {
	local $SIG{__WARN__} = \&catch_warnings;
	$COMPERR = '';

	# DON'T LOOK NOW! - blindly untainting can make you go blind!
	$block =~ /(.*)/s;
	$block = $1;

	$block = eval $block;
#	$COMPERR .= "[$@]" if $@;
#	return $class->error($COMPERR)
	return $class->error($@)
	    unless defined $block;
    }

    # same for any additional BLOCK definitions
    @$defblocks{ keys %$defblocks } = 
	# MORE BLIND UNTAINTING - turn away if you're squeamish
	map { 
	    ref($_) 
		? $_ 
		: ( /(.*)/s && eval($1) or return $class->error($@) )
	} values %$defblocks;

    bless {
	%$metadata,
	_BLOCK     => $block,
	_DEFBLOCKS => $defblocks,
	_HOT       => 0,
    }, $class;
}


#------------------------------------------------------------------------
# block()
#
# Returns a reference to the internal sub-routine reference, _BLOCK, 
# that constitutes the main document template.
#------------------------------------------------------------------------

sub block {
    return $_[0]->{ _BLOCK };
}


#------------------------------------------------------------------------
# blocks()
#
# Returns a reference to a hash array containing any BLOCK definitions 
# from the template.  The hash keys are the BLOCK nameand the values
# are references to Template::Document objects.  Returns 0 (# an empty hash)
# if no blocks are defined.
#------------------------------------------------------------------------

sub blocks {
    return $_[0]->{ _DEFBLOCKS };
}


#------------------------------------------------------------------------
# process($context)
#
# Process the document in a particular context.  Checks for recursion,
# registers the document with the context via visit(), processes itself,
# and then unwinds with a large gin and tonic.
#------------------------------------------------------------------------

sub process {
    my ($self, $context) = @_;
    my $defblocks = $self->{ _DEFBLOCKS };
    my $output;


    # check we're not already visiting this template
    return $context->throw(Template::Constants::ERROR_FILE, 
			   "recursion into '$self->{ name }'")
	if $self->{ _HOT } && ! $context->{ RECURSION };   ## RETURN ##

    $context->visit($defblocks);
    $self->{ _HOT } = 1;
    eval {
	my $block = $self->{ _BLOCK };
	$output = &$block($context);
    };
    $self->{ _HOT } = 0;
    $context->leave();

    die $context->catch($@)
	if $@;
	
    return $output;
}


#------------------------------------------------------------------------
# AUTOLOAD
#
# Provides pseudo-methods for read-only access to various internal 
# members. 
#------------------------------------------------------------------------

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
#    my ($pkg, $file, $line) = caller();
#    print STDERR "called $self->AUTOLOAD($method) from $file line $line\n";
    return $self->{ $method };
}


#========================================================================
#                     -----  PRIVATE METHODS -----
#========================================================================


#------------------------------------------------------------------------
# _dump()
#
# Debug method which returns a string representing the internal state
# of the object.
#------------------------------------------------------------------------

sub _dump {
    my $self = shift;
    my $dblks;
    my $output = "$self : $self->{ name }\n";

    $output .= "BLOCK: $self->{ _BLOCK }\nDEFBLOCKS:\n";

    if ($dblks = $self->{ _DEFBLOCKS }) {
	foreach my $b (keys %$dblks) {
	    $output .= "    $b: $dblks->{ $b }\n";
	}
    }

    return $output;
}


#========================================================================
#                      ----- PACKAGE SUBS -----
#========================================================================

#------------------------------------------------------------------------
# write_perl_file($filename, \%content)
#
# This sub-routine writes the Perl code representing a compiled
# template to a file, specified by name as the first parameter.
# The second parameter should be a hash array containing a main
# template BLOCK, a hash array of additional DEFBLOCKS (named BLOCKs
# definined in the template document source) and a hash array of
# METADATA items.  The values for the BLOCK and individual BLOCKS
# entries should be strings containing Perl code representing the
# templates as compiled by the parser.
#
# Returns 1 on success.  On error, sets the $ERROR package variable
# to contain an error message and returns undef.
#
# This is a bit of an ugly hack.  It might be better if the Document
# object itself had an as_perl() method to return a Perl representation
# of itself.  But that would imply it had to store it's Perl text 
# as well as a reference to the evaluated Perl sub-routines.  Using this
# approach, we can let the new() constructor eval() the Perl code
# and then discard the source text.
#------------------------------------------------------------------------

sub write_perl_file {
    my ($file, $content) = @_;
    my ($block, $defblocks, $metadata) = 
	@$content{ qw( BLOCK DEFBLOCKS METADATA ) };
    my $pkg = __PACKAGE__;

    $defblocks = join('', 
		      map { "'$_' => $defblocks->{ $_ },\n" }
		      keys %$defblocks);

    $metadata = join('', 
		       map { 
			   my $x = $metadata->{ $_ }; 
			   $x =~ s/(['\\])/\\$1/g; 
			   "'$_' => '$x',\n";
		       } keys %$metadata);

    local *CFH;
    my ($cfile) = $file =~ /^(.+)$/s or do {
	$ERROR = "invalid filename: $file";
	return undef;
    };
    sysopen(CFH, $cfile, O_CREAT|O_WRONLY|O_TRUNC) or do {
	$ERROR = $!;
	return undef;
    };

    print CFH  <<EOF;
#------------------------------------------------------------------------
# Compiled template generated by the Template Toolkit version $Template::VERSION
#------------------------------------------------------------------------

bless {
$metadata
_HOT       => 0,
_BLOCK     => $block,
_DEFBLOCKS => {
$defblocks
},
}, $pkg;
EOF
    close(CFH);

    return 1;
}


#------------------------------------------------------------------------
# catch_warnings($msg)
#
# Installed as
#------------------------------------------------------------------------

sub catch_warnings {
    $COMPERR .= join('', @_); 
}

    
1;

__END__


#------------------------------------------------------------------------
# IMPORTANT NOTE
#   This documentation is generated automatically from source
#   templates.  Any changes you make here may be lost.
# 
#   The 'docsrc' documentation source bundle is available for download
#   from http://www.template-toolkit.org/docs.html and contains all
#   the source templates, XML files, scripts, etc., from which the
#   documentation for the Template Toolkit is built.
#------------------------------------------------------------------------

=head1 NAME

Template::Document - Compiled template document object

=head1 SYNOPSIS

    use Template::Document;

    $doc = Template::Document->new({
	BLOCK => sub { # some perl code; return $some_text },
	DEFBLOCKS => {
	    header => sub { # more perl code; return $some_text },
	    footer => sub { # blah blah blah; return $some_text },
	},
	METADATA => {
	    author  => 'Andy Wardley',
	    version => 3.14,
	}
    }) || die $Template::Document::ERROR;

    print $doc->process($context);

=head1 DESCRIPTION

This module defines an object class whose instances represent compiled
template documents.  The Template::Parser module creates a
Template::Document instance to encapsulate a template as it is compiled
into Perl code.

The constructor method, new(), expects a reference to a hash array
containing the BLOCK, DEFBLOCKS and METADATA items.  The BLOCK item
should contain a reference to a Perl subroutine or a textual
representation of Perl code, as generated by the Template::Parser
module, which is then evaluated into a subroutine reference using
eval().  The DEFLOCKS item should reference a hash array containing
further named BLOCKs which may be defined in the template.  The keys
represent BLOCK names and the values should be subroutine references
or text strings of Perl code as per the main BLOCK item.  The METADATA
item should reference a hash array of metadata items relevant to the
document.

The process() method can then be called on the instantiated
Template::Document object, passing a reference to a Template::Content
object as the first parameter.  This will install any locally defined
blocks (DEFBLOCKS) in the the contexts() BLOCKS cache (via a call to
visit()) so that they may be subsequently resolved by the context.  The 
main BLOCK subroutine is then executed, passing the context reference
on as a parameter.  The text returned from the template subroutine is
then returned by the process() method, after calling the context leave()
method to permit cleanup and de-registration of named BLOCKS previously
installed.

An AUTOLOAD method provides access to the METADATA items for the document.
The Template::Service module installs a reference to the main 
Template::Document object in the stash as the 'template' variable.
This allows metadata items to be accessed from within templates, 
including PRE_PROCESS templates.

header:

    <html>
    <head>
    <title>[% template.title %]
    </head>
    ...

Template::Document objects are usually created by the Template::Parser
but can be manually instantiated or sub-classed to provide custom
template components.

=head1 METHODS

=head2 new(\%config)

Constructor method which accept a reference to a hash array containing the
structure as shown in this example:

    $doc = Template::Document->new({
	BLOCK => sub { # some perl code; return $some_text },
	DEFBLOCKS => {
	    header => sub { # more perl code; return $some_text },
	    footer => sub { # blah blah blah; return $some_text },
	},
	METADATA => {
	    author  => 'Andy Wardley',
	    version => 3.14,
	}
    }) || die $Template::Document::ERROR;

BLOCK and DEFBLOCKS items may be expressed as references to Perl subroutines
or as text strings containing Perl subroutine definitions, as is generated
by the Template::Parser module.  These are evaluated into subroutine references
using eval().

Returns a new Template::Document object or undef on error.  The error() class
method can be called, or the $ERROR package variable inspected to retrieve
the relevant error message.

=head2 process($context)

Main processing routine for the compiled template document.  A reference to 
a Template::Context object should be passed as the first parameter.  The 
method installs any locally defined blocks via a call to the context 
visit() method, processes it's own template, passing the context reference
by parameter and then calls leave() in the context to allow cleanup.

    print $doc->process($context);

Returns a text string representing the generated output for the template.
Errors are thrown via die().

=head2 block()

Returns a reference to the main BLOCK subroutine.

=head2 blocks()

Returns a reference to the hash array of named DEFBLOCKS subroutines.

=head2 AUTOLOAD

An autoload method returns METADATA items.

    print $doc->author();

=head1 PACKAGE SUB-ROUTINES

=head2 write_perl_file(\%config)

This package subroutine is provided to effect persistance of compiled
templates.  If the COMPILE_EXT option (to indicate a file extension
for saving compiled templates) then the Template::Parser module call
this subroutine before calling the new() constructor.  At this stage,
the parser has a representation of the template as text strings
containing Perl code.  We can write that to a file, enclosed in a
small wrapper which will allow us to susequently require() the file
and have Perl parse and compile it into a Template::Document.  Thus we
have persistance of compiled templates.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

L<http://www.andywardley.com/|http://www.andywardley.com/>




=head1 VERSION

2.49, distributed as part of the
Template Toolkit version 2.07, released on 17 April 2002.

=head1 COPYRIGHT

  Copyright (C) 1996-2002 Andy Wardley.  All Rights Reserved.
  Copyright (C) 1998-2002 Canon Research Centre Europe Ltd.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template|Template>, L<Template::Parser|Template::Parser>