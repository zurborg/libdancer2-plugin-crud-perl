FORMAT: 1A

# x-name

x-intro

# Group person

C

## Index [/api/persons.{format}]

### Index [GET]

D 1

+ Parameters

    + format (required, string)

        + Values

            + `json`
            + `yaml`
            + `dump`

+ Request JSON (application/json)

    + `/api/persons.json`

    + Headers

            E: 1

    + Body

            [
               "F",
               "1"
            ]


+ Response 200 (application/json)

    + Headers

            H: 1

    + Body

            [
               "I",
               "1"
            ]


+ Request YAML (text/x-yaml)

    + `/api/persons.yml`

    + Headers

            E: 1

    + Body

            ---
            - F
            - '1'


+ Response 200 (text/x-yaml)

    + Headers

            H: 1

    + Body

            ---
            - I
            - '1'


+ Request DUMP (text/x-perl)

    + `/api/persons.dump`

    + Headers

            E: 1

    + Body

            [
              'F',
              '1'
            ]


+ Response 200 (text/x-perl)

    + Headers

            H: 1

    + Body

            [
              'I',
              '1'
            ]


## Create [/api/person.{format}]

### Create [POST]

D 2

+ Parameters

    + format (required, string)

        + Values

            + `json`
            + `yaml`
            + `dump`

+ Request JSON (application/json)

    + `/api/person.json`

    + Headers

            E: 2

    + Body

            [
               "F",
               "2"
            ]


+ Response 200 (application/json)

    + Headers

            H: 2

    + Body

            [
               "I",
               "2"
            ]


+ Request YAML (text/x-yaml)

    + `/api/person.yml`

    + Headers

            E: 2

    + Body

            ---
            - F
            - '2'


+ Response 200 (text/x-yaml)

    + Headers

            H: 2

    + Body

            ---
            - I
            - '2'


+ Request DUMP (text/x-perl)

    + `/api/person.dump`

    + Headers

            E: 2

    + Body

            [
              'F',
              '2'
            ]


+ Response 200 (text/x-perl)

    + Headers

            H: 2

    + Body

            [
              'I',
              '2'
            ]


## Read Update Patch Delete [/api/person/{person_id}.{format}]

### Read [GET]

D 3

+ Parameters

    + format (required, string)

        + Values

            + `json`
            + `yaml`
            + `dump`

    + person_id (required, (?^:[^\/\.\:\?]+))

+ Request JSON (application/json)

    + `/api/person/{person_id}.json`

    + Headers

            E: 3

    + Body

            [
               "F",
               "3"
            ]


+ Response 200 (application/json)

    + Headers

            H: 3

    + Body

            [
               "I",
               "3"
            ]


+ Request YAML (text/x-yaml)

    + `/api/person/{person_id}.yml`

    + Headers

            E: 3

    + Body

            ---
            - F
            - '3'


+ Response 200 (text/x-yaml)

    + Headers

            H: 3

    + Body

            ---
            - I
            - '3'


+ Request DUMP (text/x-perl)

    + `/api/person/{person_id}.dump`

    + Headers

            E: 3

    + Body

            [
              'F',
              '3'
            ]


+ Response 200 (text/x-perl)

    + Headers

            H: 3

    + Body

            [
              'I',
              '3'
            ]


### Update [PUT]

D 4

+ Parameters

    + format (required, string)

        + Values

            + `json`
            + `yaml`
            + `dump`

    + person_id (required, (?^:[^\/\.\:\?]+))

+ Request JSON (application/json)

    + `/api/person/{person_id}.json`

    + Headers

            E: 4

    + Body

            [
               "F",
               "4"
            ]


+ Response 200 (application/json)

    + Headers

            H: 4

    + Body

            [
               "I",
               "4"
            ]


+ Request YAML (text/x-yaml)

    + `/api/person/{person_id}.yml`

    + Headers

            E: 4

    + Body

            ---
            - F
            - '4'


+ Response 200 (text/x-yaml)

    + Headers

            H: 4

    + Body

            ---
            - I
            - '4'


+ Request DUMP (text/x-perl)

    + `/api/person/{person_id}.dump`

    + Headers

            E: 4

    + Body

            [
              'F',
              '4'
            ]


+ Response 200 (text/x-perl)

    + Headers

            H: 4

    + Body

            [
              'I',
              '4'
            ]


### Patch [PATCH]

D 5

+ Parameters

    + format (required, string)

        + Values

            + `json`
            + `yaml`
            + `dump`

    + person_id (required, (?^:[^\/\.\:\?]+))

+ Request JSON (application/json)

    + `/api/person/{person_id}.json`

    + Headers

            E: 5

    + Body

            [
               "F",
               "5"
            ]


+ Response 200 (application/json)

    + Headers

            H: 5

    + Body

            [
               "I",
               "5"
            ]


+ Request YAML (text/x-yaml)

    + `/api/person/{person_id}.yml`

    + Headers

            E: 5

    + Body

            ---
            - F
            - '5'


+ Response 200 (text/x-yaml)

    + Headers

            H: 5

    + Body

            ---
            - I
            - '5'


+ Request DUMP (text/x-perl)

    + `/api/person/{person_id}.dump`

    + Headers

            E: 5

    + Body

            [
              'F',
              '5'
            ]


+ Response 200 (text/x-perl)

    + Headers

            H: 5

    + Body

            [
              'I',
              '5'
            ]


### Delete [DELETE]

D 6

+ Parameters

    + format (required, string)

        + Values

            + `json`
            + `yaml`
            + `dump`

    + person_id (required, (?^:[^\/\.\:\?]+))

+ Request JSON (application/json)

    + `/api/person/{person_id}.json`

    + Headers

            E: 6

    + Body

            [
               "F",
               "6"
            ]


+ Response 200 (application/json)

    + Headers

            H: 6

    + Body

            [
               "I",
               "6"
            ]


+ Request YAML (text/x-yaml)

    + `/api/person/{person_id}.yml`

    + Headers

            E: 6

    + Body

            ---
            - F
            - '6'


+ Response 200 (text/x-yaml)

    + Headers

            H: 6

    + Body

            ---
            - I
            - '6'


+ Request DUMP (text/x-perl)

    + `/api/person/{person_id}.dump`

    + Headers

            E: 6

    + Body

            [
              'F',
              '6'
            ]


+ Response 200 (text/x-perl)

    + Headers

            H: 6

    + Body

            [
              'I',
              '6'
            ]


