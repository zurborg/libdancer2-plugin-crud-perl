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
        idregex => 'number',
        index   => sub {
            my $app = shift;
            return [qw[ xx yy ]];
        },
        read => sub {
            my $app = shift;
            return sub {
                return { i => ++$i };
            };
        },
    );

}

plan tests => 4;

my $T = Dancer2::Plugin::CRUD::Test->new('Webservice');

subtest index_head => sub {
    plan tests => 2;
    my $R = $T->action( head => '/person', undef, expect => 200 );
    is( $R->content => '' );
};

subtest read_get_1 => sub {
    plan tests => 2;
    my $R = $T->action( read => '/person/123', undef, expect => 200 );
    is_deeply( $R->data => { i => 1 } );
};

subtest read_head => sub {
    plan tests => 2;
    my $R = $T->action( head => '/person/123', undef, expect => 200 );
    is( $R->content => '' );
};

subtest read_get_2 => sub {
    plan tests => 2;
    my $R = $T->action( read => '/person/123', undef, expect => 200 );
    is_deeply( $R->data => { i => 2 } );
};

done_testing();
