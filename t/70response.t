#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;

my $daia = response;
isa_ok( $daia, 'DAIA::Response' );

my $doc = document( id => 'my:123' );

#$daia->document( [ $doc ] );
#$daia = response( document => [ $doc ] );

my $d1 = response( $daia );
is_deeply( $d1, $daia, 'copy constructor' );

#$daia->document( [ document( id => 'my:id' ) ] );
#$d1 = response( institution => institution('foo') );
#isa_ok( $d1, "DAIA::Response" );
#$daia = response( institution => { content => 'foo' } );
#is_deeply( $daia, $d1 );

#$daia = DAIA::Response->new(
#  institution => institution( content => "..." ),
#  message => [ message( "en" => "all right" ) ]
#);

#$daia->institution( DAIA::Institution->new( "..." ) );
#my $inst = $daia->institution;

# TODO: test 'serve'

#print "\n\n" . $daia->xml . "\n\n";
#$daia->serve( xslt => "daia.xsl" );

