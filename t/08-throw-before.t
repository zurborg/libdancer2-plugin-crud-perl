#!perl -T

use lib 't';
use tests;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;

    hook before => sub {
        throw(400 => "meh");
    };

    resource( test => index => sub { 1 } );
}

my $PT = boot('Webservice');

plan( tests => 1 );

dotest(
    throw => 4,
    sub {
        my $R = request( $PT, GET => '/test.dump' );
        ok( !$R->is_success );
        is( $R->code => 400 );
        my $VAR1;
        eval $R->content;
        ok( !$@ );
        cmp_deeply(
            $VAR1,
            {
                message => "meh",
                status  => 400,
                title   => 'Error 400 - Bad Request',
            }
        );
    }
);

done_testing();
