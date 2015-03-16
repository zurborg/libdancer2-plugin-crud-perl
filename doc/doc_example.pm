package doc_example;

use Dancer2;
use Dancer2::Plugin::CRUD;
use Dancer2::Plugin::CRUD::Documentation;

resource("person",
    index => sub
        :Description( List all persons in this room )
        :RequestBody( { limit => 10 } )
        :ResponseBody( [{ name => 'Alice' },{ name => 'Bob' }] )
    {
        my $app = shift;
    },
);

publish_apiblueprint("/doc", id => 'default');

1;

