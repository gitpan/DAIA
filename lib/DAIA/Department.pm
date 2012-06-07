use strict;
use warnings;
package DAIA::Department;
{
  $DAIA::Department::VERSION = '0.421';
}
#ABSTRACT: Information about a department in a L<DAIA::Institution>

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;


__END__
=pod

=head1 NAME

DAIA::Department - Information about a department in a L<DAIA::Institution>

=head1 VERSION

version 0.421

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Department is a subclass of.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

