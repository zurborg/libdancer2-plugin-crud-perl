#!perl

use lib 't';
require tests;

package Webservice {

    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(foo =>
        index => sub : AllowHtml {
            var hello => 'Hello, ';
            return {
                world => 'World!',
            };
        },
        read => sub : AllowHtml Template(show) {
            my ($self, %ids) = @_;
            return \%ids;
        },
        update => sub : AllowHtml Template(bar) Template(edit) {
            my ($self, %ids) = @_;
            return \%ids;
        },
        create => sub : AllowHtml {
            return {json=>to_json(request->data->multi)};
        }
    );

    1;
}

my $PT = boot('Webservice');

#plan( tests => 2 );

dotest(
    foo_index => 2,
    sub {
        my $R = request( $PT, GET => '/foo.html' );
        is( $R->code => 200 );
        is( $R->content => 'Hello, World!' );
    }
);

dotest(
    foo_read => 2,
    sub {
        my $R = request( $PT, GET => '/foo/123.html' );
        is( $R->code => 200 );
        is( $R->content => 'The result is 123.' );
    }
);

dotest(
    foo_update => 2,
    sub {
        my $R = request( $PT, PUT => '/foo/123.html' );
        is( $R->code => 200 );
        is( $R->content => 'The result is 123.' );
    }
);

dotest(
    foo_create => 2,
    sub {
        my $R = form_request( $PT, POST => '/foo.html', [ abc => 123 ] );
        is( $R->code => 200 );
        is( $R->content => '{"abc":["123"]}' );
    }
);

done_testing();
