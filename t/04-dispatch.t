#!perl

use lib 't';
require tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        'foo_xx',
		chain    => 'dispatch',
		chain_id => 'dispatch',
        index    => 'dispatch',
        single   => sub {
            resource( 'bar_yy', dispatch => [qw[ chain chain_id index ]], );
        },
    );

    1;
}

package Webservice::FooXx {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
	sub chain    { header('X-Chain-Foo'    => 1) }
    sub index_action : Format(txt) { 'foo_xx' }
}

package Webservice::FooXx::BarYy {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
	sub chain    { header('X-Chain-Foo-Bar'    => 1) }
    sub index_action : Format(txt) { 'bar_yy' }
}

my $PT = boot('Webservice');

plan( tests => 2 );

dotest(
    foo_xx => 4,
    sub {
        my $R = request( $PT, GET => '/foo_xx.txt' );
        ok( $R->is_success );
		is ( scalar($R->header('X-Chain-Foo')), 1 );
		is ( scalar($R->header('X-Chain-Foo-Bar')), undef );
        islc( $R->content => 'foo_xx' );
    }
);

dotest(
    bar_yy => 4,
    sub {
        my $R = request( $PT, GET => '/foo_xx/bar_yy.txt' );
        ok( $R->is_success );
		is ( scalar($R->header('X-Chain-Foo')), 1 );
		is ( scalar($R->header('X-Chain-Foo-Bar')), 1 );
        islc( $R->content => 'bar_yy' );
    }
);

done_testing();
