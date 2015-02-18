#!perl

use lib 't';
require tests;

soft_require('JSON::Schema');

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;

    resource(
        'foo', create => sub : RequestSchema({
          type => 'object',
          properties => {
          x => { type => 'string', required => 1 }
          },
          }) { [ request->data ] },
    );

}

my $PT = boot('Webservice');

plan( tests => 1 );

dotest(
    foo => 1,
    sub {
        my $R = request( $PT, POST => '/foo.yaml', content => "---\nx : 1\n" );
        ok( $R->is_success );
    }
);

done_testing();
