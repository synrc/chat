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