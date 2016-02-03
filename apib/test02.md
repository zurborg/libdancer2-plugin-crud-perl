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