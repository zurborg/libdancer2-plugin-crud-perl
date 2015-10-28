#!perl -T

use Test::More;
use Dancer2::Plugin::CRUD::Test;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;

    my $i = 0;

    resource(
        "person",
        index   => sub {},
        read    => sub {},
        create  => sub {},
        update  => sub {},
        delete  => sub {},
        patch   => sub {},
    );

}

plan tests => 2;

my $T = Dancer2::Plugin::CRUD::Test->new('Webservice');

subtest index_options => sub {
    plan tests => 2;
    my $R = $T->request( options => '/person.dump' );
    is( $R->code => 200 );
    is ( scalar($R->header('Allow')), 'GET,POST' );
};

subtest read_options => sub {
    plan tests => 2;
    my $R = $T->request( options => '/person/123.dump' );
    is( $R->code => 200 );
    is ( scalar($R->header('Allow')), 'DELETE,GET,PATCH,PUT' );
};

done_testing();
