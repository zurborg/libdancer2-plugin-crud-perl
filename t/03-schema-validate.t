#!perl

use Dancer2::Plugin::CRUD::Test;

use lib 't';
use tests;

soft_require('JSON::Schema');

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        'foo',
        create => sub :
        RequestSchema({
            type => 'object',
            properties => {
                x => {
                    type => 'string',
                    required => 1,
                },
            },
        })
        {
            request->data
        },
        update => sub :
        RequestSchema({
            type => 'object',
            properties => {
                y => {
                    type => 'string',
                    required => 1,
                },
            },
        })
        {
            request->data
        },
        patch => sub :
        RequestSchema({
            type => 'object',
            properties => {
                z => {
                    type => 'string',
                    required => 1,
                },
            },
        })
        {
            request->data
        },
    );
}

my $T = Dancer2::Plugin::CRUD::Test->new('Webservice');

sub doreq {
    my ($method, $path, $good, $bad, $msg) = @_;
    subtest("$method $path" => sub {
        plan(tests => 4);

        my $G = $T->action( $method, $path, $good, expect => 200 );
        $T->compare($G => $good);

        my $B = $T->action( $method, $path, $bad , expect => 400 );
        $T->compare($B => {errors=>$msg}) or explain($B->data);

    });
}

plan(tests => 3);

doreq(
    'create',
    '/foo',
    { x=>1 },
    { y=>1 },
    { '$.x' => 'is missing and it is required' }
);

doreq(
    'update',
    '/foo/123',
    { y=>1 },
    { x=>1 },
    { '$.y' => 'is missing and it is required' }
);

doreq(
    'patch',
    '/foo/123',
    { z=>1 },
    { q=>1 },
    { '$.z' => 'is missing and it is required' }
);

done_testing();
