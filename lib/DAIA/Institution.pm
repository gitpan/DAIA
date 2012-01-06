use strict;
use warnings;
package DAIA::Institution;
{
  $DAIA::Institution::VERSION = '0.41';
}
#ABSTRACT: Organization that may hold items and provide services

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;


__END__
=pod

=head1 NAME

DAIA::Institution - Organization that may hold items and provide services

=head1 VERSION

version 0.41

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Institution is a subclass of.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

