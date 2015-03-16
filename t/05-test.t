#!perl

use Test::More;
use Scalar::Util qw(blessed);
use Dancer2::Plugin::CRUD::Test;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource( 'foo', create => sub { return request->data } );

    1;
};

my $T = Dancer2::Plugin::CRUD::Test->new('Webservice');

my $R = $T->action( create => '/foo', { 'xx' => 'yy' }, expect => 200 );
ok( defined $R );
ok( blessed $R);
ok( $R->isa('HTTP::Message') );
ok( $R->can('data') );
$T->compare( $R => { 'xx' => 'yy' } );

done_testing();
