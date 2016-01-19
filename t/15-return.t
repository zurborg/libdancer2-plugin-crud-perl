#!perl

use Test::More;
use Scalar::Util qw(blessed);
use Dancer2::Plugin::CRUD::Test;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource( 'foo', index => sub {
        return_now(300=>['good']);
        die "meh";
    } );

    1;
};

my $T = Dancer2::Plugin::CRUD::Test->new('Webservice');

my $R = $T->action( index => '/foo', undef, expect => 300 );
$T->compare( $R => ['good'] );

done_testing();
