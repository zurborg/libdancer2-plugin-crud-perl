use strictures 2;

package Dancer2::Plugin::CRUD::HTML;

# ABSTRACT: ...

use Moo;
use Carp 'croak';
use Dancer2;

with 'Dancer2::Core::Role::Serializer';

has '+content_type' => (
    default => sub {'text/html'},
);

sub deserialize {
    my ( $self, $content ) = @_;

    my $data;

    if (my $format = $self->request->header('content-type')) {
        if ($format =~ m{^(application/json|text/x-json)(|;.*)$}xsi) {
            $data = Dancer2::Core::DSL::from_json($content);
        } elsif ($format =~ m{^(application/x-www-form-urlencoded)(|;.*)$}xsi) {
            $data = $self->request->body_parameters;
        } else {
            die(415);
        }
    } else {
        $data = $self->request->body_parameters;
    }

    return $data;
}

sub serialize {
    my ( $self, $entity ) = @_;

    die "entity is still a ".ref($entity) if ref $entity;
    return $entity;

}

1;
