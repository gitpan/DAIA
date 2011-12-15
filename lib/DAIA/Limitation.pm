use strict;
use warnings;
package DAIA::Limitation;
{
  $DAIA::Limitation::VERSION = '0.4';
}
#ABSTRACT: Information about specific limitations of availability

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;


__END__
=pod

=head1 NAME

DAIA::Limitation - Information about specific limitations of availability

=head1 VERSION

version 0.4

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Limitation is a subclass of.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

