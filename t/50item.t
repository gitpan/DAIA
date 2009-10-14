#!perl -Tw                                                                                                  

use strict;
use Test::More qw( no_plan );
use DAIA;

my $item = item();
isa_ok( $item, 'DAIA::Item' );

### storage
is( $item->storage, undef );

$item->storage( storage() );
is_deeply( $item->struct, { storage => { content => "" } } );

$item->storage(undef);
is( $item->storage, undef );

my @s = ( ['foo'], ['id' => 'my:id'], [ 'baz', 'id' => 'my:id' ],
          [ {content=>'foo',href=>'http://example.com'} ] );
foreach (@s) {
    my $storage = storage( @{$_} );
    $item->storage( @{$_} );
    is_deeply( item( storage => $storage ), $item );
}

$item->add( storage('hey' ) );
is_deeply( $item->struct, { storage => { content => "hey" } } );

$item->storage( undef );
is_deeply( $item->struct, { } );

$item->addMessage( 'hey' );
is_deeply( $item->struct, { message => [ { content => "hey", lang => "en" } ] } );

## department
## ...

# Signatur (auch undef!)

$item->addAvailable( "loan" );

$item->addService( "loan" => 1 );


# fragment (xs:boolean)
use JSON;

$item = item();
my @true = ( 1, 'true', $JSON::true, 42 );
foreach my $t (@true) {
    $item->fragment(undef);
    $item->fragment($t);
    ok( $item->fragment, 'fragment true' );
}
like( $item->json, qr/{\s*"fragment"\s*:\s*true\s*}/ );
like( $item->xml, qr/<item\s+fragment\s*=\s*"true"\s*\/>/ );

my @false = ( 0, 'false', $JSON::false, 'FALSE' );
foreach my $t (@false) {
    $item->fragment(undef);
    $item->fragment($t);
    ok( ! $item->fragment, 'fragment false' );
}
like( $item->json, qr/\{\s*"fragment"\s*:\s*false\s*\}/ );
like( $item->xml, qr/<item\s+fragment\s*=\s*"false"\s*\/>/ );

# label
$item->fragment( undef );
$item->label( "hi" );
is( $item->label, "hi" );
$item->label( "" );
is( $item->label, "" );
$item->label( undef );
is( $item->label, "" );


