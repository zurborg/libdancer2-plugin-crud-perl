#!perl

use lib 't';
require tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        {
            foo => {
                index => sub : Format(txt) { 'foo' },    # /foo.txt => sub
                single => {
                    bar => {
                        index =>
                          'dispatch',   # /foo/bar.txt => Foo::Bar::index_action
                        plural => {
                            baf => {
                                dispatch => ['index']
                                , # /foo/bar/baf.txt => Foo::Bar::Baf::index_action
                            }
                        },
                        single_id => {
                            baz => {
                                dispatch => ['index']
                                , # /foo/bar/:id/baz.txt => Foo::Bar::Baz::index_action
                            }
                        }
                    }
                }
            }
        }
    );

    1;
}

package Webservice::Foo::Bar {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    sub index_action : Format(txt) { 'foo_bar' }
}

package Webservice::Foo::Bar::Baf {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    sub index_action : Format(txt) { 'foo_bar_baf' }
}

package Webservice::Foo::Bar::Baz {
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    sub index_action : Format(txt) { 'foo_bar_baz' }
}

my $PT = boot('Webservice');

plan( tests => 4 );

dotest(
    foo => 2,
    sub {
        my $R = request( $PT, GET => '/foo.txt' );
        ok( $R->is_success );
        islc( $R->content => 'foo' );
    }
);

dotest(
    foo_bar => 2,
    sub {
        my $R = request( $PT, GET => '/foo/bar.txt' );
        ok( $R->is_success );
        islc( $R->content => 'foo_bar' );
    }
);

dotest(
    foo_bar_baf => 2,
    sub {
        my $R = request( $PT, GET => '/foo/bar/baf.txt' );
        ok( $R->is_success );
        islc( $R->content => 'foo_bar_baf' );
    }
);

dotest(
    foo_bar_baz => 2,
    sub {
        my $R = request( $PT, GET => '/foo/bar/123/baz.txt' );
        ok( $R->is_success );
        islc( $R->content => 'foo_bar_baz' );
    }
);

done_testing();
