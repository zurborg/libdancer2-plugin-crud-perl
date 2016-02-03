use strictures 2;

package Dancer2::Plugin::CRUD::Response;

use Moo 2;
use Dancer2::Core::Types;
use Dancer2::Core::HTTP;

=attr status

=cut

has status => (
    is      => 'ro',
    isa     => Num,
    default => sub { 200 },
    lazy    => 1,
    coerce  => sub { Dancer2::Core::HTTP->status(shift) },
);

=attr entity

=cut

has entity => (
    is => 'ro',
);

=method return

=cut

sub return {
    my $self = shift;
    return (
        $self->status,
        $self->entity,
    );
}

1;

