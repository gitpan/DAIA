package DAIA::Response;

=head1 NAME

DAIA::Response - DAIA information root element

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = $DAIA::Object::VERSION;
use strict;
use Carp qw(croak);
use POSIX qw(strftime);

=head1 SYNOPSIS

  $r = response( # or DAIA::Response->new( 
      institution => $institution,
      message => [ $msg1, $msg2 ],
      document => [ $document ]
  );

  $r->institution( $institution );
  $institution = $r->institution;

  my $documents = $r->document;

  $r->timestamp;
  $r->version;

=head1 PROPERTIES

=over

=item document

a list of L<DAIA::Document> objects.

=item institution

a L<DAIA::Institution> that grants or knows about the documents, 
items services and availabilities described in this response.

=item message

a list of L<DAIA::Message> objects.

=item timestamp

date and time of the response information. It must match the pattern of
C<xs:dateTime> and is set to the current date and time on initialization.

=back

The additional read-only attribute B<version> gives the current version of
DAIA format.

=cut

our %PROPERTIES = (
    version => {
        default => '0.5', 
        filter => sub { '0.5' }
    },
    timestamp => {
        default => sub { strftime("%Y-%m-%dT%H:%M:%SZ", gmtime); },
        filter => sub { $_[0] } # TODO
    },
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    institution => { 
        type => 'DAIA::Institution',
    },
    document => { 
        type => 'DAIA::Document',
        repeatable => 1
    },
);

=head1 METHODS

DAIA::Response provides the default methods of L<DAIA::Object>, accessor 
methods for all of its properties and the following methods:

=head2 addMessage ( $message | ... )

Add a specified or a new L<DAIA::Message>.

=head2 addDocument ( $document | %properties )

Add a specified or a new L<DAIA::Document>.

=head2 serve ( [ [ format => ] $format ] [ %options ] )

Serialize the response and send it to STDOUT with the appropriate HTTP headers.
The required format (C<json> or C<xml> as default) can specified with the first
parameter or the C<format> option. If no format is given, it is searched for in
the CGI query parameters. Other possible options are

=over

=item header

Print HTTP headers (default). Use C<header =E<gt> 0> to disable headers.

=item xslt

Add a link to the given XSLT stylesheet if XML format is requested.

=item callback

Add this JavaScript callback function in JSON format. If no callback
function is specified, it is searched for in the CGI query parameters.
You can disable callback support by setting C<callback => undef>.

=back

=cut

sub serve {
    my $self = shift;
    my (%attr) = @_ % 2 ? ( 'format', @_ ) : @_;
    my $format = exists $attr{'format'} ? lc($attr{'format'}) : CGI::param('format'); # TODO: use Apache::
    my $header = defined $attr{header} ? $attr{header} : 1;
    my $xslt = $attr{xslt};

    if ( $format eq 'json' ) {
        print CGI::header( '-type' => "application/javascript; charset=utf-8" ) if $header;
        my $callback = exists $attr{callback} ? $attr{callback} : CGI::param('callback');
        print $self->json( $attr{callback} );
    } else {
        print CGI::header( -type => "application/xml; charset=utf-8" ) if $header;
        print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        print "<?xml-stylesheet type=\"text/xsl\" href=\"$xslt\"?>\n" if $xslt;

        # TODO add 'xmlns' option
        # Use a given XML namespace prefix in XML format. The default namespace
        # prefix is C<d>. You should only need this if your clients don't use
        # namespace-aware XML parsers.

        print $self->xml( xmlns => "" );
    }
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
