#!perl

use lib 't';
require tests;

#plan(skip_all => 'work in progress');

{
    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::CRUD;
    use Dancer2::Plugin::CRUD::Documentation;
    
    resource({
        'person(s)' => {
            description => 'this is sparta',
            index => sub :
                Description(foo)
                { ... },
            read => sub {...},

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
                            index => sub :
                                { ... },

                        }
                    }, # single_id
                } # bar
            } # single
        } # person(s)
    });

    our $doc = Dancer2::Plugin::CRUD::get_doc_till_here();
}

sub _show;
sub _show {
    my $docs = shift // return;
    foreach my $doc (@$docs) {
        explain({
            name => $doc->{name},
            #idtype => $doc->{idtype},
            (map { $_ => $doc->{$_} } qw(index create read update patch delete)),
        });
        #note(explain([keys %$doc]));
        _show($doc->{children});
    }
}

#_show ($Webservice::doc);

explain($Webservice::doc);

explain(Dancer2::Plugin::CRUD::Documentation::generate_apiblueprint($Webservice::doc));

ok(1);

done_testing();
