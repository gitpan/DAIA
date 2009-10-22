#!/usr/bin/perl

=head1 NAME

daiaformat.pl - Simple DAIA parser/converter as CGI and command line client

=cut

use strict;
use utf8;
use Encode;
use CGI qw(:standard);
use LWP::Simple qw(get);
use Data::Dumper;
use CGI::Carp qw(fatalsToBrowser);
use DAIA;

=head1 DESCRIPTION

You can pass either an URL which will be queried, a string of serialized DAIA.
The serialization format (JSON or XML) can be specified or it will get guessed.
You can use this as a proxy to convert serialization or just show the result in
HTML - in this case you can also validate DAIA/XML against the XML Schema.

=head1 COMMAND LINE USAGE

  daiaformat.pl input.xml  out=json  # convert to DAIA/JSON (default)
  daiaformat.pl input.json out=xml   # convert to DAIA/XML

=cut

my $url       = param('url');
my $data      = param('data');
my $informat  = lc(param('in'));
my $outformat = lc(param('out'));
my $callback  = param('callback'); 
$callback = "" unless $callback =~ /^[a-z][a-z0-9._\[\]]*$/i;

my ($error, $daia);

my $xsd = "daia.xsd";

# icoming raw data is UTF-8
eval{ $data = Encode::decode_utf8( $data ); };

$url = $data if (@ARGV and $data =~ /^\s*http[s]?:\/\//);

if ($url) {
    # fetched data is already UTF-8
    $data = get($url) or $error = "Failed to fetch data via URL";
}


if (not $error and $data ) {
    $daia = eval { DAIA->parse( data => $data, format => $informat ) };
    $error = $@ if $@;
} elsif( @ARGV ) { # called from command line
    my $file = shift;
    $daia = eval { DAIA->parse( file => $file, format => $informat ) };
    if ( $@ ) {
        print STDERR "$@\n";
    } else {
        binmode STDOUT, "utf8";
        if ($outformat eq 'xml') {
            print $daia->xml(xmlns => 1);
        } elsif($outformat eq 'dump') {
            print Dumper($daia);
        } else {
            print $daia->json;
        }
        print "\n";
    }
    exit;
}

if ( $outformat =~ /^(json|xml)$/ ) {
    my $xslt = "daia.xsl";
    $xslt = undef unless -f $xslt;
    $daia->serve( format => $outformat, callback => $callback, xslt => $xslt );
} elsif ( $outformat and $outformat ne 'html' ) {
    $error = "Unknown output format - using HTML instead";
}

# HTML output
$error = "<div class='error'>".escapeHTML($error)."!</div>" if $error;

print header(-charset => 'UTF-8');
print <<HTML;
<html>
<head>
  <title>DAIA Converter</title>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
  <style>
    body { font-family: arial, sans-serif;}
    h1, p { margin: 0; text-align: center; }
    form { margin: 1em; border: 1px solid #333; }
    fieldset { border: 1px solid #fff; }
    label, .error { font-weight: bold; }
    .submit, .error { font-size: 120%; }
    .error { color: #A00; margin: 1em; }
  </style>
</head>
<body>
<h1>DAIA Converter</h1>
<p>Convert and Validate <a href="http://purl.org/NET/DAIA">DAIA response format</a></p>
<form method="get" accept-charset="utf-8" action="">
HTML
print $error,
  fieldset(label('Input: ',
        popup_menu('in',['','json','xml'],'',
                   {''=>'Guess','json'=>'DAIA/JSON','xml'=>'DAIA/XML'})
  )),
  fieldset('either', label('URL: ', textfield(-name=>'url', -size=>70)),
    'or', label('Data:'),
    textarea( -name=>'data', -rows=>20, -cols=>80 ),
  ),
  fieldset(
    label('Output: ',
        popup_menu('out',['html','json','xml'],'html',
                   {'html'=>'HTML','json'=>'DAIA/JSON','xml'=>'DAIA/XML'})
    ), '&#xA0;', 
    label('JSONP Callback: ', textfield('callback'))
  ),
  fieldset('<input type="submit" value="Convert" class="submit" />'),
  "</form>"
;
print p("data was fetched from URL - input field was ignored")
    if ($url and not $error and param('data'));
if ($daia) {
  if ( $informat eq 'xml' or DAIA::guess($data) eq 'xml' ) {
    my ($schema, $parser); # TODO: move this into a DAIA library method
    eval { require XML::LibXML; };
    if ( $@ ) {
        $error = "XML::LibXML::Schema required to validate DAIA/XML";
    } else {
        $parser = XML::LibXML->new;
        $schema = eval { XML::LibXML::Schema->new( location => $xsd ); };
        if ($schema) {
            my $doc = $parser->parse_string( $data );
            eval { $schema->validate($doc) };
            $error = "DAIA/XML not valid but parseable: " . $@ if $@;
        } else {
            $error = "Could not load XML Schema - validating was skipped";
        }
    }
    if ( $error ) {
      print "<p class='error'>".escapeHTML($error)."</p>";
    } else {
      print p("DAIA/XML valid according to ".a({href=>$xsd},"this XML Schema"));
    }
  } else {
     print p("validation is rather lax so the input may be invalid - but it was parseable");
  }
  print "<h2>Result in DAIA/JSON</h2>";
  binmode(STDOUT, ":utf8");
  print pre(escapeHTML( $daia->json( $callback ) ));
  print "<h2>Result in DAIA/XML</h2>";
  print pre(escapeHTML( $daia->xml( xmlns => 1 ) ) );
  #if ( $data ) { #and $url ) {
  #  print "<h2>Dump</h2>";
  #  print pre(escapeHTML( Dumper($daia) ));
  #  print "<h2>Source</h2>";
  #  print pre(escapeHTML( $data ));
  #}
}
print "</body>";




