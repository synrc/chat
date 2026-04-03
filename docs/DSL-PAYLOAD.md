# DSL Payload

## Structured message payload
```
scenario structured send + structured expect
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "hi"
    subject: "Draft"
    priority: high
  }

  session bob1
  expect message from alice {
    body: "hi"
    subject: "Draft"
    priority: high
  }
```

```
scenario short send + structured expect
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob "hello"

  session bob1
  expect message from alice {
    body: "hello"
  }
```

```
scenario structured send + short expect
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "ping"
    priority: high
  }

  session bob1
  expect message from alice body "ping"
```

```
scenario partial payload match
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "doc"
    subject: "Order"
    amount: 1000
  }

  session bob1
  expect message from alice {
    subject: "Order"
  }
```

```
scenario payload types
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "types"
    amount: 42
    urgent: true
    priority: high
  }

  session bob1
  expect message from alice {
    amount: 42
    urgent: true
    priority: high
  }
```

```
scenario payload mismatch
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "x"
    subject: "A"
  }

  session bob1
  expect not message from alice {
    subject: "B"
  }
```

```
scenario payload edit field
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "doc"
    subject: "Draft"
    priority: high
  }

  session alice1
  edit message "doc" field subject "Draft v2"

  session bob1
  expect message from alice {
    subject: "Draft v2"
  }
```

```
scenario payload edit does not affect other fields
  session alice1
  connect
  auth

  session bob1
  connect
  auth

  session alice1
  send message to bob {
    body: "doc"
    subject: "A"
    priority: high
  }

  session alice1
  edit message "doc" field subject "B"

  session bob1
  expect message from alice {
    subject: "B"
    priority: high
  }
```

## Given payload support
```
scenario given payload baseline
  given
    private feed alice<->bob has messages
      1 from alice "doc"

  session bob1
  connect
  auth

  session bob1
  expect message from alice {
    body: "doc"
  }
```

## Payload validation
```
scenario payload validation duplicate field
  session alice1
  connect
  auth

  session alice1
  send message to bob {
    body: "x"
    body: "y"
  }

  expect error badRequest
```

```
scenario payload validation missing body
  session alice1
  connect
  auth

  session alice1
  send message to bob {
    subject: "Draft"
    priority: high
  }

  expect error badRequest
```

```
scenario payload validation invalid body type
  session alice1
  connect
  auth

  session alice1
  send message to bob {
    body: 42
    subject: "Draft"
  }

  expect error badRequest
```

```
scenario payload validation nested object unsupported
  session alice1
  connect
  auth

  session alice1
  send message to bob {
    body: "x"
    meta: {}
  }

  expect error badRequest
```

```
scenario payload validation array unsupported
  session alice1
  connect
  auth

  session alice1
  send message to bob {
    body: "x"
    tags: []
  }

  expect error badRequest
```

```
scenario given structured payload
  given
    private feed alice<->bob has messages
      1 from alice {
        body: "doc"
        subject: "Draft"
        priority: high
      }

  session bob1
  connect
  auth

  session bob1
  expect message from alice {
    body: "doc"
    subject: "Draft"
    priority: high
  }
```


## TODO

- payload + replay after reconnect
- payload + snapshot / inbox bootstrap consistency
- payload + edit then replay final-state verification
- payload + delete final-state verification
- payload visibility across replay / inbox / home boundaries
