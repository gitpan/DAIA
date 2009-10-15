#!perl -Tw                                                                                                  

use strict;
use Test::More qw( no_plan );
use DAIA;

my $item = item();

like( $item->xml( xmlns => 1 ), qr/<item xmlns="http:\/\/ws.gbv.de\/daia\/"\s*\/>/, "xlmns" );
like( $item->xml( 'xmlns' ), qr/<item xmlns="http:\/\/ws.gbv.de\/daia\/"\s*\/>/, "xlmns" );

is( message("en" => "hi")->xml, '<message lang="en">hi</message>', 'message' );

$item = item( 
  label => "\"",
  message => [ message("hi") ],
  department => { content => "foo" },
  available => [
    available('loan',  limitation => '<', message => '>',)
  ]
);
my $data = join("",<DATA>);
is ( $item->xml, $data, 'xml example' );


my $object;
# use Data::Dumper;

$object = DAIA::parse_xml( $data );
is_deeply( $object, $item, 'parsed xml' );

$object = DAIA::parse_xml( "<message lang='de' xmlns='http://ws.gbv.de/daia/'>Hallo</message>" );
is_deeply( $object, message( 'de' => 'Hallo' ), 'ignore xmlns' );

$object = DAIA::parse_xml( "<d:message lang='de' xmlns:d='http://ws.gbv.de/daia/'>Hallo</d:message>", 1 );
is_deeply( $object, message( 'de' => 'Hallo' ), 'use xmlns' );

$object = DAIA::parse_xml( "<message lang='de'>Hallo</message>" );
isa_ok( $object, "DAIA::Message" );

$object = eval { DAIA::parse_xml( "<message><foo /></message>" ); };
ok( $@, "detect errors in XML" );



# TODO: more examples (read and write), including edge cases and errors

__DATA__
<item label="&quot;">
  <message lang="en">hi</message>
  <department>foo</department>
  <available service="loan">
    <message lang="en">&gt;</message>
    <limitation>&lt;</limitation>
  </available>
</item>