#!perl

use lib 't';
use tests;

{
    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;

    resource({
        'person(s)' => {
            description => 'this is sparta',
            index => sub
                :Description(foo)
                :Description(bar)
                :RequestHeader(foo:bar)
                :RequestHeader( bar : baz )
                :RequestBody({
                    hello=>'world'
                })
                :RequestBody({
                    world=>'hello'
                })
                :ResponseHeader(abc:def)
                :ResponseHeader( def : ghi )
                :ResponseBody([1,2,3])
                :ResponseBody([4,5,6])
                :RequestSchema({type=>'object'})
                { ... },
            read => sub :
                InputFormat(png)
                InputFormat(jpg (image/jpg)) #/
                {...},
            update => sub :
                OutputFormat(html)
                {...},
            patch => sub :
                OutputFormat(abc)
                OutputFormat(def)
                {...},
            delete => sub :
                Format(xml)
                {...},

            -single => {
                bar => {
                    index => sub :
                        { ... },

                    plural => {
                        baf => {
                            index => sub :
                                { ... },

                        } # baf
                    }, # plural

                    single_id => {
                        baz => {
                            index => sub { ... },
                            read => sub { ... },
                            create => sub { ... },
                            update => sub { ... },
                            patch => sub { ... },
                            delete => sub { ... },
                        }
                    }, # single_id
                } # bar
            } # single
        } # person(s)
    });

    our $doc = generate_documentation();
}

my $md = Dancer2::Plugin::CRUD::Documentation::generate_apiblueprint($Webservice::doc);

if ($ENV{DUMP_APIB}) {
    print STDERR $md;
    plan(skip_all => 'apib dumped');
    exit;
}

plan(tests => 1);

open(MD, '<apib/test02.md');

tdt(''.$md, ''.join('' => <MD>), 'x');

close MD;

done_testing;
