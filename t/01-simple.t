#!perl -T

use lib 't';
require tests;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;

    resource(
        "person(s)",
        idregex  => 'number',
        validate => sub {
            my ( $app, $value ) = @_;
            return $value % 2 ? undef : "value $value is odd, not even";
        },

        index  => sub { shift; { index  => {@_}, chain1 => var('chain1') } },
        create => sub { shift; { create => {@_}, chain1 => var('chain1') } },
        read   => sub { shift; { read   => {@_}, chain1 => var('chain1') } },
        update => sub { shift; { update => {@_}, chain1 => var('chain1') } },
        patch  => sub { shift; { patch  => {@_}, chain1 => var('chain1') } },
        delete => sub { shift; { delete => {@_}, chain1 => var('chain1') } },

        chain => sub {
            var( chain1 => 'root' );
        },

        chain_id => sub {
            my $id = pop;
            var( chain1 => $id**2 );
        },

        single_id => sub {
            get( '/single_id' => sub { return 'single_id' } );

            resource(
                "item(s)",
                idregex  => 'number',
                validate => sub {
                    my ( $app, $value ) = @_;
                    return $value % 2 ? "value $value is even, not odd" : undef;
                },
                chain_id => sub {
                    my $id = pop;
                    var( chain2 => $id**2 );
                },
                read => sub {
                    shift;
                    {
                        read   => {@_},
                        chain1 => var('chain1'),
                        chain2 => var('chain2')
                    };
                },
            );

        },
        single => sub {
            get( '/single' => sub { 'single' } );
            resource(
                chain => index => sub { { single_chain => var('chain1') } } );
        },
        plural => sub {
            get( '/plural' => sub { 'plural' } );
            resource(
                chain => index => sub { { plural_chain => var('chain1') } } );
        },
    );

    resource( image => index => sub : Format(png) { 'this_is_not_an_image' } );

    resource( status => index => sub { return 202 => [qw[ ok ]] } );

    resource( error => index => sub { die "meh\n" } );
}

my $PT = boot('Webservice');

use Dancer2::Plugin::CRUD::Constants qw(%ext_to_fmt);
use Class::Load qw(try_load_class);

sub cmp_formats {
    my ( $PT, $method, $path, $cmp ) = @_;
    dotest(
        "$method" => 0,
        sub {
            foreach my $format (qw(yaml json dump cbor)) {
                my $pkg = 'Dancer2::Serializer::' . $ext_to_fmt{$format};
                next unless ( try_load_class($pkg) );
                my $obj = $pkg->new;
                dotest(
                    "$path.$format" => 3,
                    sub {
                        my $R = request( $PT, $method, $path . '.' . $format );
                        unless ( ok( $R->is_success, "is success" ) ) {
                            diag( "status code: " . $R->code );
                            return;
                        }
                        my $data = $obj->deserialize( $R->content );
                        ok( $data, "data ok" );
                        cmp_deeply( $data, $cmp, "data compared" );
                    }
                );
            }
        }
    );
}

plan( tests => 6 );

dotest(
    icrupd => 6,
    sub {
        cmp_formats(
            $PT,
            GET => '/persons',
            { index => {}, chain1 => 'root' }
        );
        cmp_formats(
            $PT,
            POST => '/person',
            { create => {}, chain1 => 'root' }
        );
        cmp_formats(
            $PT,
            GET => '/person/123',
            { read => { person_id => 123 }, chain1 => 123**2 }
        );
        cmp_formats(
            $PT,
            PUT => '/person/123',
            { update => { person_id => 123 }, chain1 => 123**2 }
        );
        cmp_formats(
            $PT,
            PATCH => '/person/123',
            { patch => { person_id => 123 }, chain1 => 123**2 }
        );
        cmp_formats(
            $PT,
            DELETE => '/person/123',
            { delete => { person_id => 123 }, chain1 => 123**2 }
        );
    }
);

dotest(
    static => 3,
    sub {
        dotest(
            single_id => 2,
            sub {
                my $R = request( $PT, GET => '/person/123/single_id' );
                ok( $R->is_success );
                isfc( $R->content => 'single_id' );
            }
        );
        dotest(
            single => 2,
            sub {
                my $R = request( $PT, GET => '/person/single' );
                ok( $R->is_success );
                isfc( $R->content => 'single' );
            }
        );
        dotest(
            plural => 2,
            sub {
                my $R = request( $PT, GET => '/persons/plural' );
                ok( $R->is_success );
                isfc( $R->content => 'plural' );
            }
        );
    }
);

dotest(
    chain1 => 3,
    sub {
        cmp_formats(
            $PT,
            GET => '/person/123/item/456',
            {
                read   => { person_id => 123, item_id => 456 },
                chain1 => 123**2,
                chain2 => 456**2
            }
        );
        cmp_formats(
            $PT,
            GET => '/person/chain',
            { single_chain => 'root' }
        );
        cmp_formats(
            $PT,
            GET => '/persons/chain',
            { plural_chain => 'root' }
        );
    }
);

dotest(
    image => 2,
    sub {
        my $R = request( $PT, GET => '/image.png' );
        ok( $R->is_success );
        isfc( $R->content => 'this_is_not_an_image' );
    }
);

dotest(
    status => 3,
    sub {
        my $R = request( $PT, GET => '/status.json' );
        ok( $R->is_success );
        is( $R->code => 202 );
        isfc( $R->content => '["ok"]' );
    }
);

dotest(
    error => 4,
    sub {
        my $R = request( $PT, GET => '/error.dump' );
        ok( !$R->is_success );
        is( $R->code => 500 );
        my $VAR1;
        eval $R->content;
        ok( !$@ );
        cmp_deeply(
            $VAR1,
            {
                message => "meh\n",
                status  => 500,
                title   => 'Error 500 - Internal Server Error',
            }
        );
    }
);

done_testing();
