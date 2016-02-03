#!perl

use lib 't';
use tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        'foo',
        index    => 'deny',
        single   => sub {
            resource( 'bar', deny => [qw[ index ]], );
        },
    );

    1;
}

my $PT = boot('Webservice');

plan( tests => 2 );

dotest(
    foo => 1,
    sub {
        my $R = request( $PT, GET => '/foo.dump' );
        is( $R->code => 405 );
    }
);

dotest(
    bar => 1,
    sub {
        my $R = request( $PT, GET => '/foo/bar.dump' );
        is( $R->code => 405 );
    }
);

done_testing();
