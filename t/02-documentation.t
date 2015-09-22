#!perl

use lib 't';
require tests;

plan(skip_all => 'work in progress');

__END__

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;

    resource(
        "person(s)",
        description => 'C',
        index       => sub : Description(D 1) : RequestHeaders(E: 1) :
          RequestBody([qw[F 1]]) : ResponseHeaders(H: 1) :
          ResponseBody([qw[I 1]]) { ... },
        create => sub : Description(D 2) : RequestHeaders(E: 2) :
          RequestBody([qw[F 2]]) : ResponseHeaders(H: 2) :
          ResponseBody([qw[I 2]]) { ... },
        read => sub : Description(D 3) : RequestHeaders(E: 3) :
          RequestBody([qw[F 3]]) : ResponseHeaders(H: 3) :
          ResponseBody([qw[I 3]]) { ... },
        update => sub : Description(D 4) : RequestHeaders(E: 4) :
          RequestBody([qw[F 4]]) : ResponseHeaders(H: 4) :
          ResponseBody([qw[I 4]]) { ... },
        patch => sub : Description(D 5) : RequestHeaders(E: 5) :
          RequestBody([qw[F 5]]) : ResponseHeaders(H: 5) :
          ResponseBody([qw[I 5]]) { ... },
        delete => sub : Description(D 6) : RequestHeaders(E: 6) :
          RequestBody([qw[F 6]]) : ResponseHeaders(H: 6) :
          ResponseBody([qw[I 6]]) { ... },
    );

    publish_apiblueprint(
        '/doc1',
        name   => 'x-name',
        intro  => 'x-intro',
        prefix => '/api',
    );

}

my $PT = boot('Webservice');

plan( tests => 1 );

dotest(
    doc1 => 2,
    sub {
        my $R = request( $PT, GET => '/doc1.md' );
        ok( $R->is_success );
        my $file = 'doc1.md';
        if ( $ENV{CREATE_DOCUMENTATION} ) {
            open( APIMD, ">$file" ) or die "cannot write $file: $!";
            ok( print APIMD $R->content );
            close APIMD;
        }
        else {
            open( APIMD, "<$file" ) or die "cannot read $file: $!";
            my $should = join '' => <APIMD>;
            close APIMD;
            is( $R->content => $should );
        }
    }
);

done_testing();
