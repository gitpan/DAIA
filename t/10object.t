#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;

my $item = item();
isa_ok( $item, 'DAIA::Item' );

my $item2 = item($item);
is_deeply( $item2, $item, 'copy constructor' );

$item->add();
is_deeply( $item, $item2, 'add nothing' );

$item->add(undef);
is_deeply( $item, $item2, 'add undef = nothing' );

$item = item()->fragment(0)->message( ["foo","bar"] );

$item = DAIA::parse( '{ "item" : { "id" : "my:id" } }' );
isa_ok( $item, "DAIA::Item" );
is_deeply( $item->struct, { "id" => "my:id" } );
