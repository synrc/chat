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

- payload + id-based mutation semantics (exact protocol identity)
- payload + event vs state alignment across replay / inbox / home
- payload + edge cases for mutation ordering and convergence

```text
## PAYLOAD-REPLAY-1. Structured payload survives replay after reconnect

scenario structured payload survives replay after reconnect

given
  private feed alice<->bob has messages
    1 from alice {
      body: "doc"
      subject: "Draft"
      priority: high
    }

session bob
connect
auth

query events peer alice after 0

expect message from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}
```

- replay повинен відтворювати structured payload, а не тільки `body`
- reconnect/replay не повинен втрачати додаткові payload fields

---

## PAYLOAD-REPLAY-2. Structured payload survives inbox snapshot
```
scenario structured payload survives inbox snapshot

given
private feed alice<->bob has messages
1 from alice {
body: "doc"
subject: "Draft"
priority: high
}

session bob
connect
auth

query inbox peer alice
expect snapshot

expect message from alice {
body: "doc"
subject: "Draft"
priority: high
}
```

- inbox/snapshot view повинен повертати той самий structured payload
- snapshot не повинен редукувати payload до одного `body`

---

## PAYLOAD-REPLAY-3. Field edit converges in replay to final payload
```
scenario field edit converges in replay to final payload

given
  private feed alice<->bob has messages
    1 from alice {
      body: "doc"
      subject: "Draft"
      priority: high
    }

session alice
connect
auth
edit message ref "doc" field subject "Draft v2"

session bob
connect
auth
query events peer alice after 0

expect message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

- після field-level edit replay повинен конвергувати до final payload
- старе значення `subject: "Draft"` не повинно лишатися current state

---

## PAYLOAD-REPLAY-4. Delete removes structured payload from current replay state
```
scenario delete removes structured payload from current replay state

given
private feed alice<->bob has messages
1 from alice {
body: "doc"
subject: "Draft"
priority: high
}

session alice
connect
auth
delete message ref "doc"

session bob
connect
auth
query events peer alice after 0

expect message deleted
expect not message from alice {
body: "doc"
subject: "Draft"
priority: high
}
```

- після delete replay не повинен показувати stale structured payload як current state
- delete повинен перекривати видимість payload у current replay/inbox semantics

---

## PAYLOAD-HOME-1. Structured payload survives home bootstrap
```
scenario structured payload survives home bootstrap

given
  alice has bob in roster
  private feed alice<->bob has messages
    1 from alice {
      body: "doc"
      subject: "Draft"
      priority: high
    }

session bob
connect
auth

bootstrap home

expect shared snapshot
query inbox peer alice

expect message from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}
```

- home/bootstrap не повинен втрачати structured payload
- feed, відкритий через home bootstrap, повинен давати той самий final payload

---

## PAYLOAD-HOME-2. Field edit survives home bootstrap
```
scenario field edit survives home bootstrap

given
  alice has bob in roster
  private feed alice<->bob has messages
    1 from alice {
      body: "doc"
      subject: "Draft"
      priority: high
    }

session alice
connect
auth
edit message ref "doc" field subject "Draft v2"

session bob
connect
auth

bootstrap home

expect shared snapshot
query inbox peer alice

expect message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

- home/bootstrap повинен сходитися до final payload після field-level edit
- bootstrap не повинен повертати stale версію payload

---

## PAYLOAD-HOME-3. Delete hides structured payload after home bootstrap
```
scenario delete hides structured payload after home bootstrap

given
  alice has bob in roster
  private feed alice<->bob has messages
    1 from alice {
      body: "doc"
      subject: "Draft"
      priority: high
    }

session alice
connect
auth
delete message ref "doc"

session bob
connect
auth

bootstrap home

expect shared snapshot
query inbox peer alice

expect message deleted
expect not message from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}
```

- після delete home/bootstrap не повинен відновлювати stale structured payload
- inbox після bootstrap повинен відображати current final state
