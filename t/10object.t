#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;

my $item = item();
isa_ok( $item, 'DAIA::Item' );

my $item2 = item($item);
is_deeply( $item2, $item, 'copy constructor' );

#$item->storage('here');
#my $item2 = item( storage => storage( 'there'  ) );

$item->add();
is_deeply( $item, $item2, 'add nothing' );

$item->add(undef);
is_deeply( $item, $item2, 'add undef = nothing' );

$item->label( "foo" );
is( $item->label, "foo", "label" );

__END__

$item->struct( { storage => { 'foo' } } );

print $item->json;

ok(1);

#    ; # nothing
#    $h->add( undef ); # nothing
