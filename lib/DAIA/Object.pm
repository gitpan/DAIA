package DAIA::Object;

=head1 NAME

DAIA::Object - Abstract base class of all DAIA classes

=cut

use strict;
use Carp qw(croak confess);
use Data::Validate::URI qw(is_uri is_web_uri);
use JSON;
use XML::Writer;
use XML::Simple; # XMLOut;
#use XML::Simple;
# TODO: XML  Parser ?

our $VERSION = $DAIA::VERSION;
our $AUTOLOAD;

=head1 DESCRIPTION

This package implements just another Perl meta-class framework. Just
ignore it unless you have a clue what "meta-class framework" could 
mean. Some concepts are borrowed from the mighty L<Moose> object system
but this framework is much smaller. Maybe you should better have a look 
at Moose and stop reading now.

In a nutshell C<DAIA::Object> handles all method calls via AUTOLOAD.
Each derived package must provide a C<%PROPERTIES> hash that defines
an object's attributes. Each property is defined by a hash that must
either contain a C<type> value pointing to a class name (typed property)
or a C<filter> value containing a plain value ar a filter method (untyped
property).

=head1 METHDOS

=head2 Constructor methods

All derived DAIA classed use this constructor. As C<DAIA::Object> is an
abstract base class directly calling is of little use.

=head3 new ( ..attributes... )

Constructs a new DAIA object. Unknown properties are ignored.

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;

    my %hash;
    if ( @_ == 1 and ref($_[0]) eq 'HASH' ) {
        %hash = %{$_[0]};
    } elsif ( @_ == 1 and ref($_[0]) eq $class ) {
        %hash = %{$_[0]->struct}; # copy constructor
    } else {
        %hash = $self->_buildargs(@_);
    }

    # abstract class handling
    if ( $class eq 'DAIA::Availability' ) {
        croak "Availability status missing" unless exists $hash{status};
        $self->status( $hash{status} );
        delete $hash{status};
        $class = ref($self);
    }

    no strict 'refs'; ##no critic
    my $PROPERTIES = \%{$class."::PROPERTIES"};
    foreach my $property (keys %{$PROPERTIES}) {
        $self->$property( undef ) unless exists $hash{$property};
    }
    foreach my $property (keys %hash) {
        $self->$property( $hash{$property} );
    }

    # print Dumper($self)."\n";
    return $self;
}

=head2 Modification methods

=head3 add ( ... )

Adds typed properties to an object.

=cut

sub add {
    my $self = shift;

    #print "APPEND: " . ref($self) . "\n";

    foreach my $value (@_) {
        next unless defined $value; # ignore undefined values

        #print "- " . ref($value) . "\n";

        confess "Cannot add $value to " . ref($self) 
            unless ref($value) =~ /^DAIA::([A-Z][a-z]+)$/;
        my $property = lc($1);
    
        #no strict 'refs';
        #my $PROPERTIES = \%{$class."::PROPERTIES"};
        
        # repeatable
        if ( ref($self->{$property}) eq 'ARRAY' ) {
            push @{$self->{$property}}, $value;
        } else {
            $self->$property( $value );
        }
    }
}

=head2 Serialization methods

A DAIA object can be serialized by the following methods:

=head3 xml ( [ %options ] )

Returns the object in DAIA/XML. The current implementation
does not know element order, so it breaks the XML Schema.

=cut

sub xml {
    my ($self, %opt) = @_;

    my $name = lc(ref($self)); 
    $name =~ s/^daia:://;
    $name = 'daia' if $name eq 'response';

    # TODO: indent parameter?
    my $xml;
    my $struct = $self->struct;

    if (defined $opt{xmlns}) { # TODO: clarify and document this parameter
        $struct->{xmlns} = "http://ws.gbv.de/daia/";
    }

    # TODO: the order of elements is not controlled but the XML Schema wants !
    # we could use Tie:
    # For some XML document types you might be able to hack it in by subclassing
    # XML::Simple and overriding the new_hashref() method to supply a hashref tied to Tie::IxHash.

    $xml = XMLout( $struct, RootName => $name );
    # alternativ:
    # rekursiv struct durchlaufen
    # wenn ref($value) eq 'ARRAY' => mehrere children
    # wenn ref($value) eq 'HASH' => ein child
    # sonst: attribute
    # für response und item: feste reihenfolge, d.h. children sortieren
    # sonst: @children einfach so (reihenfolge egal)

    return $xml;
}

=head3 struct ( [ $json ] )

Returns the object as unblessed Perl data structure. If you specify a true parameter,
only boolean values will be kept as blessed C<JSON::Boolean> objects (see L<JSON>).
The C<label> property will only be included unless it is not the empty string.

=cut

sub struct {
    my ($self, $json) = @_;
    my $struct = { };
    foreach my $property (keys %$self) {
        if (ref $self->{$property} eq 'ARRAY') {
            $struct->{$property} = [ map { $_->struct($json) } @{$self->{$property}} ];
        } elsif ( UNIVERSAL::isa( $self->{$property}, "DAIA::Object" ) ) {
            $struct->{$property} = $self->{$property}->struct;
        } elsif ( UNIVERSAL::isa( $self->{$property}, 'JSON::Boolean' ) and not $json ) {
            $struct->{$property} = $self->{$property} ? 'true' : 'false';
        } elsif( $property eq 'label' and $self->{$property} eq '' ) {
            # ignore empty string label
        } else {
            $struct->{$property} = $self->{$property};
        }
    }
    return $struct;
}

=head2 json ( [ $callback ] )

Returns the object in DAIA/JSON, optionally wrapped by a JavaScript callback 
function call. Invalid callback names are ignored without warning.

=cut

sub json {
    my ($self, $callback) = @_;
    my $json = JSON->new->pretty->encode( $self->struct(1) );
    if ( defined $callback and $callback =~ /^[a-z][a-z0-9._\[\]]*$/i ) {
        return "$callback($json);"
    } else {
        return $json;
    }
}

=head1 INTERNAL METHODS

The following methods are only used internally; don't directly
call or modify them unless you want to damage data integrity or 
to fix a bug!

=cut

=head2 AUTOLOAD

Called if an unknown method is called. Almost all method calls go through
this magic method. Thanks, AUTOLOAD, thanks Perl.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) or croak "$self is not an object";

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';   

    my $property = $method;
    $property = lc($2) if $property =~ /^(add|provide)([A-Z][a-z]+)$/;

#print "\nSELF: " . Dumper($self);
#print "$class->$property( " . Dumper(\@_) . ");\n";

    no strict 'refs'; ##no critic
    my $PROPERTIES = \%{$class."::PROPERTIES"};

    confess "Method $class->$method ($property) does not exist"
        unless exists $PROPERTIES->{$property};

    my $opt = $PROPERTIES->{$property};

    if ( $method =~ /^add/ ) {
        confess "$class->$property is not repeatable or has no type"
            unless $opt->{repeatable} and $opt->{type};
        my $value = $_[0];
        if ( not UNIVERSAL::isa( $_[0], $opt->{type} ) ) {
          $value = eval $opt->{type}."->new( \@_ )"; ##no critic
          croak $@ if $@;
        }
        return $self->add( $value );
    } elsif( $method =~ /^provide/ ) { # set only if not set
        if ( defined $self->{$property} ) {
            # getter
            return $opt->{repeatable} ? @{$self->{$property} || []} : $self->{$property}
        } else {
            return eval "\$self->$property(\@_)";  ##no critic
        }
    }

    # called as getter
    return $opt->{repeatable} ? @{$self->{$property} || []} : $self->{$property}
        if ( @_ == 0 );

    my $value = $_[0];

    # called as clearer (implies possibly setting the default value)
    if (not defined $value or (ref($value) eq 'ARRAY' and @{$value} == 0)) {
        if ( exists $opt->{default} ) {
#print "use default value\n";
            $value = ref($opt->{default}) eq 'CODE' 
                   ? $opt->{default}() : $opt->{default};
        } 
#print "V: $value\n";
        if ( defined $value ) {  
            $self->{$property} = $value;
        } else {
            delete $self->{$property} if exists $self->{$property};
        }
#print Dumper($self);
        return;
    }

    # filter attributes (if a filter is defined)
    if( $opt->{filter} ) {
        $value = $opt->{filter}( @_ );
        confess "$class->$property did not pass value constraint"
            unless defined $value;
        $self->{$property} = $value;
        return;
    }
#print "---\n";
#print Dumper($opt);

    #$value = [ $value ] unless 
    if ( $opt->{type} ) {

        # make $value an array reference
        $value = \@_ unless @_ == 1 and ref($value) eq 'ARRAY'; 

        # make $value[0] to be of right type
        if ( UNIVERSAL::isa( $value->[0], $opt->{type} ) ) {
            foreach ( @{$value} ) {
                croak "$class->$property can only have values of class " . $opt->{type}
                    unless UNIVERSAL::isa( $_, $opt->{type} );
            }
        } else {
            $value = [ eval $opt->{type}."->new( \@{\$value} )" ];  ##no critic
            croak $@ if $@;
        }

        if ( $opt->{repeatable} ) {
            $self->{$property} = $value;
        } else {
            croak "$class->$property is not repeatable"
                if (@{$value} > 1);
            $self->{$property} = $value->[0];
        }

    } else { # untyped values are never repeatable
        $self->{$property} = "$value"; # stringify all non-objects
    }

    #print "!!!!!!!!!1\n";
    #use Data::Dumper; print Dumper($value) . "\n";
}

=head2 _buildargs

Returns a property-value hash of constructor parameters.

=cut

sub _buildargs {
    # TODO croak on un-even-list
    shift; @_; 
};


# some constants
our %COMMON_PROPERTIES =( 
    id => {
        filter => sub { my $v = "$_[0]"; is_uri($v) ? $v : undef; }
    },
    href => { 
        filter => sub { my $v = "$_[0]"; is_web_uri($v) ? $v : undef; }
    },
    message => { 
        type => 'DAIA::Message',
        repeatable => 1
    },
);

1;

=head1 BUGS

The XML serialization does not use the right element order and there is
no strict parsing mode yet. More examples will be included too.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

__END__

ELEMENT ORDER:

response:
!  institution? (element) - information about the institution that grants or knows about services and their availability
   message* (element) - (error) message(s) about the whole response
   document*
      message
      item

item
!  label? (element) - a label that helps to identify and/or find the item (signature etc.)
!  department? (element) - an administrative sub-entitity of the institution that is responsible for this item
!  storage? (element) - a physical location of the item (stacks, floor etc.)
   message* (element) - (error) message(s) about the item.
   available* (element) - information about an available service with the item.
   unavailabile*

    my $xml = "<$name";
    my @children;
    my $content = $self->{content};

    #foreach my $property (keys %$self) {
    #    if (ref $self->{$property} eq 'ARRAY') { # children
    #        $struct->{$property} = [ map { $_->struct } @{$self->{$property}} ];
    #    } elsif ( UNIVERSAL::isa( $self->{$property}, "DAIA::Object" ) ) {
    #        $struct->{$property} = $self->{$property}->struct;
    #    } else { # attribute
    #        $struct->{$property} = $self->{$property};
    #    }
    #}
    # TODO: " " x ($elementLevel * $dataIndent)
    if ( @children ) {
        $xml .= ">\n" . join( "\n", @children ) . "</$name>";
    } elsif ( defined $content ) {
        # TODO encode content
        $xml .= $content . "</$name>";
    } else {
        $xml .= " />";
    }
