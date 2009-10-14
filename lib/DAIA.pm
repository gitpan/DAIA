package DAIA;

=head1 NAME

DAIA - Document Availability Information API in Perl

=cut

use strict;
our $VERSION = '0.20'; # reused for all DAIA packages

=head1 DESCRIPTION

The Document Availability Information API (DAIA) defines a data model with 
serializations in JSON and XML to encode information about the current 
availability of documents. See L<http://purl.org/NET/DAIA> for a detailed
specification - please read it to get to know the meaning of the DAIA
information objects which are directly mapped to Perl packages.

This package provides Perl classes and functions to easily create and manage
DAIA information. It can be used to implement DAIA servers, clients, and other
programs that handle availability information.

=SYNOPSIS

A DAIA server can be implemented the following way:

  use DAIA;

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

  $res->serve( xslt => "http://path.to/daia.xsl' );

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

# TODO: change carp mode
use Carp qw(verbose);
# use Carp::Clan qw(verbose);
# or: use Carp::Clan qw(^DAIA::)

=head2 EXPORTED FUNCTIONS

If you prefer function calls in favor of constructor calls, this package 
providesfunctions for each DAIA class constructor. The functions are named 
by the object that they create but in lowercase - for instance C<response>
for the L<DAIA::Response> object. The functions can be exported in groups:

=over 4

=item :core

C<response> (L<DAIA::Response>),
C<document> (L<DAIA::Document>), 
C<item> (L<DAIA::Item>),
C<available> (L<DAIA::Available>), 
C<unavailable> (L<DAIA::Unavailable>), 
C<availability> (L<DAIA::Availability>)

=item :entities

C<institution> (L<DAIA::Institution>),
C<department> (L<DAIA::department>),
C<storage> (L<DAIA::Storage>),
C<limitation> (L<DAIA::Limitation>)

=item message

C<message> (L<DAIA::Message>)

=item serve

Calls the method method C<serve> of L<DAIA::Response> so you 
can choose between function or method calling syntax:

  serve( $response, @additionlArgs );
  $response->serve( @additionlArgs );

=back

By default all functions are exported (group C<:all>).

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

sub serve {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1; 
    shift->serve( @_ );
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
