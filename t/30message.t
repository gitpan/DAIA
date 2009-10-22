#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;
use Data::Dumper;

my $msg = new DAIA::Message;
isa_ok( $msg, 'DAIA::Message' );

my $content = "Hallo!";
my $lang = "de";
my $errno = -1;


### without error code or errno = undef
my $m1 = DAIA::Message->new( content => $content, lang => $lang );
is_deeply( $m1->struct, { content => $content, lang => $lang } );

my @constructors = (
  message( { content => $content, lang => $lang } ),
  message( content => $content, lang => $lang, errno => undef ),
  message( $lang => $content ),
  message( $content, lang => $lang ),   
  message( lang => $lang, content => $content ),
  message( $m1 ), # copy constructor 
);

foreach my $msg (@constructors) {
    is_deeply( $msg, $m1 );
}

$msg = message( $content ),
$msg->lang( $lang );
is_deeply( $msg, $m1 );


### with error code
my $m2 = DAIA::Message->new( content => $content, lang => $lang, errno => $errno );

$msg = message( $lang => $content, errno => $errno );
is_deeply( $msg, $m2 );

$msg = message();
$msg->content( $content );
$msg->lang( $lang );
is_deeply( $msg, $m1 );

$msg->errno( -1  );
is_deeply( $msg, $m2 );

$msg->errno( undef ); # remove
is_deeply( $msg, $m1 );

$msg = message( $lang => $content, $errno );
is_deeply( $msg, $m2 );

is( $m2->content, $content );
is( $m2->lang, $lang );
is( $m2->errno, $errno );

### change the default language

is( $DAIA::Message::DEFAULT_LANG, 'en' );

$m1->lang('en');
$msg = message( $content );
is_deeply( $msg, $m1 );

$m2->lang('en');
$msg = message( $content, errno => $errno );
is_deeply( $msg, $m2 );

$DAIA::Message::DEFAULT_LANG = 'de';
$m1->lang('de');
$msg = message( $content );
is_deeply( $msg, $m1 );


#### message accessors

my @holders = (
    response(),
    document( id => 'my:id' ),
    item(),
    available('loan')
);

my ($msg1, $msg2) = ( message('hi'), message('ho') );

foreach my $h ( @holders ) {
    is( $h->message, 0, 'no default message'. ref($h) );

    $h->message( [ $msg1 ] ); # array reference
    my @msgs = $h->message;
    is_deeply( $msgs[0], $msg1, 'message setter: array reference' );

    $h->message( $msg2 ); # single message
    @msgs = $h->message;
    is_deeply( $msgs[0], $msg2, 'message setter: single message' );

    $h->add( message('ho') ); # add
    @msgs = $h->message;
    is( scalar @msgs, 2, 'message and add' );


    $h->addMessage( 'hi' );
    @msgs = $h->message;
    is( scalar @msgs, 3 );

    $h->message( message('foo') );
    is_deeply( $h->message, message('foo') );


    $h->message( 'bar' );
    is_deeply( $h->message, message('bar') );

    $h->message( [ $msg1, $msg2 ] );
    @msgs = $h->message;
    is( scalar @msgs, 2 );

    $h->message( undef );
    is( $h->message, 0, 'unset by message(undef)' );

    $h->message( [ $msg ] );
    is( $h->message, 1, 'set by array reference' );

    $h->message( $msg1, $msg2 );
    @msgs = $h->message;
    is_deeply( \@msgs, [ $msg1, $msg2 ], 'set multiple in list' );

    $h->message( [] );
    is( $h->message, 0, 'unset by empty array reference' );

    $h->message( $msg );
    @msgs = $h->message;
    is( scalar @msgs, 1 );

    #$h->message( 'foo', $msg, 'bar' );
    #@msgs = $h->message;
    #is( scalar @msgs, 3 );
}


# language code
eval { message( lang => '123', content => 'hello' ); };
ok( $@, 'invalid language tag' );

# errno
$msg = message( 'hej', errno => 7 );
is( $msg->errno, 7, 'errno' );
eval { $msg->errno( 'x' ); };
ok( $@, 'invalid errno' );

$msg->errno( undef );
is_deeply( $msg->struct, { content => 'hej', lang => 'de' } );