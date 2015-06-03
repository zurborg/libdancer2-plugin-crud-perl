#!perl

use lib 't';
require tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        'foo_xx',
        index  => 'dispatch',
        single => sub {
            resource( 'bar_yy', dispatch => [qw[ index ]], );
        },
    );

    1;
}

package Webservice::FooXx {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    sub index_action : Format(txt) { 'foo_xx' }
}

package Webservice::FooXx::BarYy {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    sub index_action : Format(txt) { 'bar_yy' }
}

my $PT = boot('Webservice');

plan( tests => 2 );

dotest(
    foo_xx => 2,
    sub {
        my $R = request( $PT, GET => '/foo_xx.txt' );
        ok( $R->is_success );
        islc( $R->content => 'foo_xx' );
    }
);

dotest(
    bar_yy => 2,
    sub {
        my $R = request( $PT, GET => '/foo_xx/bar_yy.txt' );
        ok( $R->is_success );
        islc( $R->content => 'bar_yy' );
    }
);

done_testing();
