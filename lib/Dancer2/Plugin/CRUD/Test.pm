use strictures 1;

package Dancer2::Plugin::CRUD::Test;

# ABSTRACT: Testing Dancer2::Plugin::CRUD applications

=head1 SYNOPSIS

	use Dancer2::Plugin::CRUD::Test;
	
	my $T = Dancer2::Plugin::CRUD::Test->new('My::WebService');
	
	my $R = $T->action(create => '/echo', { 'xx' => 'yy' }, expect => 200);
	$T->is_deeply($R => { 'xx' => 'yy' });

=cut

use Moo;
use Carp qw(croak);
use Test::More;
use Plack::Test           ();
use HTTP::Request::Common ();
use Class::Load qw(load_class);
use Dancer2::Serializer::Dumper;
use Dancer2::Plugin::CRUD::Constants qw(%trigger_to_method);
use Sub::Name;

# VERSION

sub _redefine {
    my ( $class, $name, $coderef ) = @_;
    ## no critic
    no warnings 'redefine';
    no strict 'refs';
    *{"${class}::${name}"} = subname( $name => $coderef );
    ## use critic
}

=attr app

=cut

has app => ( is => 'ro', );

=attr PT

=cut

has PT => ( is => 'ro', );

my $S = Dancer2::Serializer::Dumper->new;

_redefine(
    'HTTP::Message',
    data => sub {
        my $self = shift;
        $self->{_data} = shift if @_;
        return $self->{_data};
    }
);

_redefine(
    'HTTP::Message',
    compare => sub {
        is_deeply( shift()->data, shift() );
    }
);

sub BUILDARGS {
    my $self  = shift;
    my $class = shift;
    load_class($class);
    my $app = $class->to_app;
    my $PT  = Plack::Test->create($app);
    return { app => $app, PT => $PT };
}

=method request

Perform a simple request for use with L<HTTP::Request::Common>:

	use HTTP::Request::Common;
	$T->request(GET '/foo');
	$T->request(POST '/bar', [ xx => 'yy' ]);

=cut

sub request {
    my $self = shift;
    return $self->PT->request( HTTP::Request::Common::_simple_req(@_) );
}

=method action ($action, $path, $body, %options)

Perform a CRUD request with automatic (de-)serialization.

	my $R = $T->action(index => '/foo'); # requests GET /foo.dump

The returned L<HTTP::Message> object is extened with an extra method called I<data()>. It holds the deserialized body of the response.

	my $data = $R->data;
	my $foo = $data->{foo};

No content will be appened to request when C<$body> is undef.

The response can be be automatically checked when C<$options{expect}> is set

	my $R = $R->action($action, $path, $body, expect => 200);
	# is($R->code => 200);

=cut

sub action {
    my ( $self, $action, $path, $body, %rest ) = @_;
    my $method = $trigger_to_method{$action}
      || croak "unknown action '$action'";
    my @content = $body ? ( content => $S->serialize($body) ) : ();
    my $expect = delete( $rest{expect} ) || 0;
    my $R = $self->request( uc($method), $path . '.dump', %rest, @content, );
    is( $R->code => $expect ) if $expect;
    return unless defined wantarray;
    my $res = $S->deserialize( $R->decoded_content );
    $R->data($res);
    return $R;
}

=method compare ($response, $expect)

Compares deep structures of the response.

	$T->compare($R, $expect);

which is the same as

	$R->compare($expect);

and thats is the same as

	use Test::More;
	is_deeply($R->data, $expect);

=cut

sub compare {
    my ( $self, $R, $expect ) = @_;
    return $R->compare($expect);
}

1;

__END__

=for Pod::Coverage BUILDARGS

