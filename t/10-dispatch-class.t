#!perl

use lib 't';
use tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use lib 't/lib';

    resource({
        foo => {
            class => 'myapp::foo',
        },
    });

    1;
}

my $PT = boot('Webservice');

plan( tests => 6 );

dotest('foo index' => 3,  sub {
    my $R = request( $PT, GET => '/foo.dump' );
    is($R->code => 200);
    my $VAR1;
    eval $R->content;
    ok(!$@) or diag($R->content."\n$@");
    cmp_deeply($VAR1, ['Dancer2::Core::App',0]) or diag(explain($VAR1));
});

dotest('foo create' => 3,  sub {
    my $R = request( $PT, POST => '/foo.dump' );
    is($R->code => 200);
    my $VAR1;
    eval $R->content;
    ok(!$@) or diag($R->content."\n$@");
    cmp_deeply($VAR1, ['Dancer2::Core::App',1]) or diag(explain($VAR1));
});

dotest('foo read' => 3,  sub {
    my $R = request( $PT, GET => '/foo/123.dump' );
    is($R->code => 200);
    my $VAR1;
    eval $R->content;
    ok(!$@) or diag($R->content."\n$@");
    cmp_deeply($VAR1, ['Dancer2::Core::App',2]) or diag(explain($VAR1));
});

dotest('foo update' => 3,  sub {
    my $R = request( $PT, PUT => '/foo/123.dump' );
    is($R->code => 200);
    my $VAR1;
    eval $R->content;
    ok(!$@) or diag($R->content."\n$@");
    cmp_deeply($VAR1, ['Dancer2::Core::App',3]) or diag(explain($VAR1));
});

dotest('foo delete' => 3,  sub {
    my $R = request( $PT, DELETE => '/foo/123.dump' );
    is($R->code => 200);
    my $VAR1;
    eval $R->content;
    ok(!$@) or diag($R->content."\n$@");
    cmp_deeply($VAR1, ['Dancer2::Core::App',4]) or diag(explain($VAR1));
});

dotest('foo patch' => 3,  sub {
    my $R = request( $PT, PATCH => '/foo/123.dump' );
    is($R->code => 200);
    my $VAR1;
    eval $R->content;
    ok(!$@) or diag($R->content."\n$@");
    cmp_deeply($VAR1, ['Dancer2::Core::App',5]) or diag(explain($VAR1));
});

done_testing();
