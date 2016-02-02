#!perl

use lib 't';
require tests;

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
                :RequestHeader(foo: bar)
                :RequestHeader(bar: baz)
                :RequestBody({
                    hello=>'world'
                })
                :RequestBody({
                    world=>'hello'
                })
                :ResponseHeader(abc: def)
                :ResponseHeader(def: ghi)
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

tdt(''.$md, ''.join('' => <DATA>), 'x');

done_testing;

__DATA__
FORMAT: 1A8

# Title of generated API blueprint file

And the description of it

# Group person

## /persons.{format}

foo

bar

+ Parameters

    + format: (enum[string], optional)
    
        + Members
        
            + `json` - application/json
            + `yml` - text/yaml

### Index [GET]

Request Schema

```
{
   "type" : "object"
}

```

+ Request JSON (application/json)

    + Headers
    
            Foo: bar
            Bar: baz
    
    + Body
    
        ```json
        {
           "hello" : "world"
        }
        
        ```

+ Request JSON (application/json)

    + Headers
    
            Foo: bar
            Bar: baz
    
    + Body
    
        ```json
        {
           "world" : "hello"
        }
        
        ```

+ Response 200 (application/json)

    + Headers
    
            Abc: def
            Def: ghi
    
    + Body
    
        ```json
        [
           1,
           2,
           3
        ]
        
        ```

+ Response 200 (application/json)

    + Headers
    
            Abc: def
            Def: ghi
    
    + Body
    
        ```json
        [
           4,
           5,
           6
        ]
        
        ```

+ Request YAML (text/yaml)

    + Headers
    
            Foo: bar
            Bar: baz
    
    + Body
    
        ```yaml
        ---
        hello: world
        
        ```

+ Request YAML (text/yaml)

    + Headers
    
            Foo: bar
            Bar: baz
    
    + Body
    
        ```yaml
        ---
        world: hello
        
        ```

+ Response 200 (text/yaml)

    + Headers
    
            Abc: def
            Def: ghi
    
    + Body
    
        ```yaml
        ---
        - 1
        - 2
        - 3
        
        ```

+ Response 200 (text/yaml)

    + Headers
    
            Abc: def
            Def: ghi
    
    + Body
    
        ```yaml
        ---
        - 4
        - 5
        - 6
        
        ```

## /person/{person_id}.{format}



+ Parameters

    + person_id: `456` (string, optional)
    
    + format: (enum[string], optional)
    
        + Members
        
            + `json` - application/json
            + `yml` - text/yaml

### Read [GET]

## /person/{person_id}.html



+ Parameters

    + person_id: `456` (string, optional)

### Update [PUT]

## /person/{person_id}.{format}



+ Parameters

    + person_id: `456` (string, optional)
    
    + format: (enum[string], optional)
    
        + Members
        
            + `abc` - abc
            + `def` - def

### Patch [PATCH]

## /person/{person_id}.xml



+ Parameters

    + person_id: `456` (string, optional)

### Delete [DELETE]