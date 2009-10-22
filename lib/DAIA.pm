package DAIA;

=head1 NAME

DAIA - Document Availability Information API in Perl

=cut

use strict;
our $VERSION = '0.25';
use IO::File;
use XML::Simple; # only for parsing (may be changed)

=head1 DESCRIPTION

The Document Availability Information API (DAIA) defines a data model with 
serializations in JSON and XML to encode information about the current 
availability of documents. See L<http://purl.org/NET/DAIA> for a detailed
specification. This package provides Perl classes and functions to easily
create and manage DAIA information. It can be used to implement DAIA servers,
clients, and other programs that handle availability information.

The DAIA information objects as decriped in the DAIA specification are
directly mapped to Perl packages. In addition a couple of functions can
be exported if you prefer to handle DAIA data without much object-orientation.

=head1 SYNOPSIS

A DAIA client (with some variations):

  use DAIA;
  use utf8;

  # get via URL and parse  
  use LWP::Simple;
  $daia = DAIA::parse( data => get( $url ) );

  # read a file and parse
  $daia = DAIA::parse( file => $file );

  # parse a string
  use Encode; # if incoming data is unencoded UTF-8
  $data = Encode::decode_utf8( $data ); # skip this if $data is just Unicode

  $daia = DAIA::parse( data => $string );

A DAIA server:

  use DAIA;
  use utf8;

  my $res = response(
      institution => {
        href    => "http://example.com/homepage.of.institutiong",
        content => "Name of the Institution" 
      }
  );

  my $id = '12345'; # identifier that has been queried for

  my @holdings = get_holding_information($id);  # you need to implement this!

  if ( @holdings ) {
    my $doc = document( id => $id, href => "http://example.com/docs/$id" );
    foreach my $h ( @holdings ) {
      my $item = item();

      # add some general information if you implement get_holding_... functions

      my %sto = get_holding_storage( $h );  
      $item->storage( id => $sto{id}, href => $sto{href}, $sto{name} );

      my $label = get_holding_label( $h );
      $item->label( $label );

      my $url = get_holding_url( $h );
      $item->href( $url );

      # add availability services
      my @services;

      if ( get_holding_is_here( $h ) ) {
         push @services, available('presentation'), available('loan');
      } elsif( get_holding_is_not_here( $h ) ) {
        push @services, # expected to be back in 5 days
          unavailable( 'presentation', expected => 'P5D' ),
          unavailable( 'loan', expected => 'P5D' );
      } else {
         # ... more cases (depending on the complexity of you application)
      }
      $item->add( @services );
    }
    $res->document( $doc );
  } else {
     $res->message( "en" => "No holding information found for id $id" );
  }

  $res->serve( xslt => "http://path.to/daia.xsl" );

=cut

use DAIA::Response;
use DAIA::Document;
use DAIA::Item;
use DAIA::Availability;
use DAIA::Available;
use DAIA::Unavailable;
use DAIA::Message;
use DAIA::Entity;
use DAIA::Institution;
use DAIA::Department;
use DAIA::Storage;
use DAIA::Limitation;

use base 'Exporter';
our %EXPORT_TAGS = (
    core => [qw(response document item available unavailable availability)],
    entities => [qw(institution department storage limitation)],
);
our @EXPORT_OK = ();
Exporter::export_ok_tags;
$EXPORT_TAGS{all} = [@EXPORT_OK, 'message', 'serve'];
Exporter::export_tags('all');

use Carp;
# TODO; use Carp::Clan qw(^DAIA::)

=head1 EXPORTED FUNCTIONS

If you prefer function calls in favor of constructor calls, this package  
providesfunctions for each DAIA class constructor. The functions are named  
by the object that they create but in lowercase - for instance C<response> 
for the L<DAIA::Response> object. The functions can be exported in groups. 
To disable exporting of the functions include DAIA like this: 

  use DAIA qw();      # do not export any functions
  use DAIA qw(serve); # only export function 'serve'

By default all functions are exported (group :all) in addition you can specify
the following groups:

=over 4

=item :core

Includes the functions C<response> (L<DAIA::Response>),
C<document> (L<DAIA::Document>), 
C<item> (L<DAIA::Item>),
C<available> (L<DAIA::Available>), 
C<unavailable> (L<DAIA::Unavailable>), and
C<availability> (L<DAIA::Availability>)

=item :entities

Includes the functions C<institution> (L<DAIA::Institution>),
C<department> (L<DAIA::department>),
C<storage> (L<DAIA::Storage>), and
C<limitation> (L<DAIA::Limitation>)

=back

=cut

sub response     { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Response->new( @_ ) }
sub document     { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Document->new( @_ ) }
sub item         { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Item->new( @_ ) }
sub available    { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Available->new( @_ ) }
sub unavailable  { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Unavailable->new( @_ ) }
sub availability { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Availability->new( @_ ) }
sub message      { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Message->new( @_ ) }
sub institution  { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Institution->new( @_ ) }
sub department   { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Department->new( @_ ) }
sub storage      { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Storage->new( @_ ) }
sub limitation   { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Limitation->new( @_ ) }

=head2 serve( [ [ format => ] $format ] [ %options ] )

Calls the method method C<serve> of L<DAIA::Response> or another DAIA object
to serialize and send a response to STDOUT with appropriate HTTP headers. 
You can call it this way:

  serve( $response, @additionlArgs );  # as function
  $response->serve( @additionlArgs );  # as method

=cut

sub serve {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1; 
    shift->serve( @_ );
}

=head1 ADDITIONAL FUNCTIONS

The following functions are not exportted but you can call both them as 
function and as method:

  DAIA->parse_xml( $xml );
  DAIA::parse_xml( $xml );

=head2 parse_xml( $xml, [ xmlns => 0|1 ] )

Parse DAIA/XML from a file or string. The first parameter must be a 
filename, a string of XML, or a L<IO::Handle> object. The optional 
parameter C<xmlns> defines whether parsing is namespace-aware - in
this case all elements outside the DAIA XML namespace 
C<http://ws.gbv.de/daia/> are ignored.

Parsing is more lax then the specification so it silently ignores 
elements and attributes in foreign namespaces. Returns either a DAIA 
object or croaks on uncoverable errors.

=cut

sub parse_xml {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    DAIA::parse( shift, format => 'xml', @_ );
}

=head2 parse_json( $json )

Parse DAIA/JSON from a file or string. The first parameter must be a 
filename, a string of XML, or a L<IO::Handle> object.

=cut

sub parse_json {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );    
    DAIA::parse( shift, format => 'json' );
}

=head2 parse ( $from [ %parameter ] )

Parse DAIA/XML or DAIA/JSON from a file or string. You can specify the source
as filename, string, or L<IO::Handle> object as first parameter or with the
named C<from> parameter. Alternatively you can pass a file(name) with parameter
C<file> or a string with parameter C<data> which is more secure. The C<format>
parameter (C<json> or C<xml>) is required unless the format can be detected 
automatically the following way:

=over

=item *

A scalar starting with C<E<lt>> and ending with C<E<gt>> is DAIA/XML.

=item *

A scalar starting with C<{> and ending with C<}> is DAIA/JSON.

=item *

A scalar ending with C<.json> is a DAIA/JSON.

=item *

A scalar ending with C<.xml> is a DAIA/XML.

=back

If you specify a filename with parameter C<file> it will not tried to parse
the filename as DAIA content but only as filename.

=cut

sub parse {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ($from, %param) = (@_ % 2) ? (@_) : (undef,@_);
    $from = $param{from} unless defined $from;
    $from = $param{data} unless defined $from;
    my $format = lc($param{format});
    my $file = $param{file};
    if (not defined $file and defined $from and not defined $param{data}) {
        if( ref($from) eq 'GLOB' or UNIVERSAL::isa($from, 'IO::Handle')) {
            $file = $from;
        } elsif( $from eq '-' ) {
            $file = \*STDIN;
        } elsif( $from =~ /\.(xml|json)$/ ) {
            $file = $from ;
            $format = $1 unless $format;
        }
    }
    if ( $file ) {
        if ( ! (ref($file) eq 'GLOB' or UNIVERSAL::isa( $file, 'IO::Handle') ) ) {
            $file = do { IO::File->new($file, '<:utf8') or croak("Failed to open file $file") };
        }
        # Enable :utf8 layer unless it or some other encoding has already been enabled
        # $self->{filehandle} = IO::File->new($file, '<:utf8') or croak("failed to open file $file");
        # my $fh = shift;
        # foreach my $layer ( PerlIO::get_layers( $fh ) ) {
        #     return if $layer =~ /^encoding|^utf8/;
        # }
        # binmode $fh, ':utf8';
        $from = do { local $/; <$file> };
        croak "DAIA serialization is empty" unless $from;
    }

    croak "Missing source to parse from " unless defined $from;

    $format = guess($from) unless $format;

    my $value;
    my $root = 'Response';

    if ( $format eq 'xml' ) {
        # do not look for filename (security!)
        if (defined $param{data} and guess($from) ne 'xml') {
            croak("XML is not well-formed (<...>)");
        }

        $param{xmlns} = 0 unless defined $param{xmlns};
        my $xml = eval { XMLin( $from, KeepRoot => 1, NSExpand => $param{xmlns} ); };
        croak $@ if $@;
        croak "XML does not contain DATA information" unless $xml;

        ($root, $value) = %$xml;
        $root =~ s/{[^}]+}//;
        $root = ucfirst($root);
        $root = 'Response' if $root eq 'Daia';

        _filter_xml( $value );

    } elsif ( $format eq 'json' ) {
        eval { $value = JSON->new->decode($from); };
        croak $@ if $@;
        if ( (keys %$value) == 1 ) {
            my ($k => $v) = %$value;
            if (not $k =~ /^(timestamp|message|institution|document)$/ and ref($v) eq 'HASH') {
                ($root, $value) = (ucfirst($k), $v);
            }
        }
        delete $value->{schema} if $root eq 'Response'; # ignore schema attribute
    } else {
        croak "Unknown DAIA serialization format $format";
    }

    croak "DAIA serialization is empty (maybe you forgot the XML namespace?)" unless $value;
    my $object = eval 'DAIA::'.$root.'->new( $value )';  ##no critic
    croak $@ if $@;

    return $object;    
}

=head1 guess ( $string )

Guess serialization format (DAIA/JSON or DAIA/XML) and return C<json>, C<xml> 
or the empty string.

=cut

sub guess {
    my $data = shift;
    return '' unless $data;
    return 'xml' if $data =~ m{^\s*\<.*?\>\s*$}s;
    return 'json' if $data =~ m{^\s*\{.*?\}\s*$}s;
    return '';
}

# filter out non DAIA XML elements and 'xmlns' attribute
sub _filter_xml { 
    my $xml = shift;
    map { _filter_xml($_) } @$xml if ref($xml) eq 'ARRAY';
    return unless ref($xml) eq 'HASH';

    my @del;
    foreach my $key (keys %$xml) {
        if ($key =~ /^{([^}]*)}(.*)/) {
            if ($1 eq "http://ws.gbv.de/daia/") {
                $xml->{$2} = $xml->{$1};
            } else {
                push @del, $key;
            }
        } elsif ($key =~ /^xmlns/ or $key =~ /:/) {
            push @del, $key;
        }
    }

    # remove non-daia elements
    foreach (@del) { delete $xml->{$_}; }

    # recurse
    map { _filter_xml($xml->{$_}) } keys %$xml;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
