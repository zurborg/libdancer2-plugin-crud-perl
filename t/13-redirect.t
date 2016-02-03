#!perl

use lib 't';
use tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        {
            foo => {
                index => sub {},
                single => {
                    bar => {
                        read => sub {},
                        create => sub { 123 }, # /foo/bar -> /foo/bar/:bar_id
                        plural => {
                            baf => {
                                read => sub {},
                                create => sub { 456 } # /foo/bar/baf -> /foo/bar/baf/:baf_id
                            }
                        },
                        single_id => {
                            baz => {
                                read => sub {},
                                create => sub { 789 } # /foo/bar/:bar_id/baf -> /foo/bar/:bar_id/baf/:baf_id
                            }
                        }
                    }
                }
            }
        }
    );

    1;
}

use Dancer2::Plugin::CRUD::Test;

my $T = Dancer2::Plugin::CRUD::Test->new('Webservice');

subtest('/foo/bar' => sub {
    plan(tests => 2);
    my $R = $T->action( create => '/foo/bar', {}, expect => 201 );
    is ( scalar($R->header('Location')), '/foo/bar/123.dump' );
});

subtest('/foo/bar/baf' => sub {
    plan(tests => 2);
    my $R = $T->action( create => '/foo/bar/baf', {}, expect => 201 );
    is ( scalar($R->header('Location')), '/foo/bar/baf/456.dump' );
});

subtest('/foo/bar/:bar_id/baz' => sub {
    plan(tests => 2);
    my $R = $T->action( create => '/foo/bar/123/baz', {}, expect => 201 );
    is ( scalar($R->header('Location')), '/foo/bar/123/baz/789.dump' );
});

done_testing();
