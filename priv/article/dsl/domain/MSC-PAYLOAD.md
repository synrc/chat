# MSC-PAYLOAD

## structured send + structured expect

DSL:
```text
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

MSC:
```text
msc StructuredSendStructuredExpect;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="hi", subject="Draft", priority=high});
  Server -> Bob1 : DeliverMessage({body="hi", subject="Draft", priority=high});

  condition Seen(Message(from=Alice1, body="hi", subject="Draft", priority=high));
endmsc;
```

Extensions used:
- `Seen`

## short send + structured expect

DSL:
```text
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

MSC:
```text
msc ShortSendStructuredExpect;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage("hello");
  Server -> Bob1 : DeliverMessage("hello");

  condition Seen(Message(from=Alice1, body="hello"));
endmsc;
```

Extensions used:
- `Seen`

## structured send + short expect

DSL:
```text
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

MSC:
```text
msc StructuredSendShortExpect;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="ping", priority=high});
  Server -> Bob1 : DeliverMessage({body="ping", priority=high});

  condition Seen(Message(from=Alice1, body="ping"));
endmsc;
```

Extensions used:
- `Seen`

## partial payload match

DSL:
```text
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

MSC:
```text
msc PartialPayloadMatch;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="doc", subject="Order", amount=1000});
  Server -> Bob1 : DeliverMessage({body="doc", subject="Order", amount=1000});

  condition Seen(Message(from=Alice1, subject="Order"));
endmsc;
```

Extensions used:
- `Seen`

## payload types

DSL:
```text
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

MSC:
```text
msc PayloadTypes;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="types", amount=42, urgent=true, priority=high});
  Server -> Bob1 : DeliverMessage({body="types", amount=42, urgent=true, priority=high});

  condition Seen(Message(from=Alice1, amount=42, urgent=true, priority=high));
endmsc;
```

Extensions used:
- `Seen`

## payload mismatch

DSL:
```text
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

MSC:
```text
msc PayloadMismatch;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="x", subject="A"});
  Server -> Bob1 : DeliverMessage({body="x", subject="A"});

  condition Seen(Message(from=Alice1, subject="B")) = false;
endmsc;
```

Extensions used:
- `Seen`

## payload edit field

DSL:
```text
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

MSC:
```text
msc PayloadEditField;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="doc", subject="Draft", priority=high});
  Server -> Bob1 : DeliverMessage({body="doc", subject="Draft", priority=high});

  Alice1 -> Server : EditMessage(ref="doc", field=subject, value="Draft v2");

  condition Seen(Message(from=Alice1, subject="Draft v2"));
endmsc;
```

Extensions used:
- `Seen`

## payload edit does not affect other fields

DSL:
```text
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

MSC:
```text
msc PayloadEditDoesNotAffectOtherFields;
  instance Alice1;
  instance Server;
  instance Bob1;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="doc", subject="A", priority=high});
  Server -> Bob1 : DeliverMessage({body="doc", subject="A", priority=high});

  Alice1 -> Server : EditMessage(ref="doc", field=subject, value="B");

  condition Seen(Message(from=Alice1, subject="B", priority=high));
endmsc;
```

Extensions used:
- `Seen`

## given payload baseline

DSL:
```text
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

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 from Alice with body "doc"

msc GivenPayloadBaseline;
  instance Bob1;
  instance Server;

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  condition Seen(Message(from=Alice, body="doc"));
endmsc;
```

Extensions used:
- `Seen`

## payload validation duplicate field

DSL:
```text
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

MSC:
```text
msc PayloadValidationDuplicateField;
  instance Alice1;
  instance Server;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="x", body="y"});

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## payload validation missing body

DSL:
```text
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

MSC:
```text
msc PayloadValidationMissingBody;
  instance Alice1;
  instance Server;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({subject="Draft", priority=high});

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## payload validation invalid body type

DSL:
```text
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

MSC:
```text
msc PayloadValidationInvalidBodyType;
  instance Alice1;
  instance Server;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body=42, subject="Draft"});

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## payload validation nested object unsupported

DSL:
```text
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

MSC:
```text
msc PayloadValidationNestedObjectUnsupported;
  instance Alice1;
  instance Server;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="x", meta={}});

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## payload validation array unsupported

DSL:
```text
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

MSC:
```text
msc PayloadValidationArrayUnsupported;
  instance Alice1;
  instance Server;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice1 -> Server : SendMessage({body="x", tags=[]});

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## given structured payload

DSL:
```text
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

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc GivenStructuredPayload;
  instance Bob1;
  instance Server;

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high));
endmsc;
```

Extensions used:
- `Seen`

## structured replay survives after reconnect

DSL:
```text
scenario structured replay survives after reconnect

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

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc StructuredReplaySurvivesAfterReconnect;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=0);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high));
endmsc;
```

Extensions used:
- `Seen`

## field edit converges in replay to final payload

DSL:
```text
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

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc FieldEditConvergesInReplayToFinalPayload;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : EventQuery(peer=alice, after=0);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high));
endmsc;
```

Extensions used:
- `Seen`

## delete removes structured replay state

DSL:
```text
scenario delete removes structured replay state

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

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc DeleteRemovesStructuredReplayState;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : DeleteMessage(ref="doc");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : EventQuery(peer=alice, after=0);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition FinalState(Message(ref="doc"), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high)) = false;
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## mutation by captured id

DSL:
```text
scenario mutation by captured id

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob {
  body: "doc"
  subject: "Draft"
  priority: high
} capture id as doc1

session alice
edit message id doc1 field subject "Draft v2"

session bob
expect message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

MSC:
```text
msc MutationByCapturedId;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage({body="doc", subject="Draft", priority=high});
  Server -> Bob : DeliverMessage({body="doc", subject="Draft", priority=high});

  Alice -> Server : EditMessage(id=doc1, field=subject, value="Draft v2");

  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high));
endmsc;
```

Extensions used:
- `Seen`

Notes:
- `capture id as doc1` is treated as a local alias binding for the created protocol identity; MSC core has no separate construct for that binding.

## delete by captured id

DSL:
```text
scenario delete by captured id

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob {
  body: "doc"
  subject: "Draft"
  priority: high
} capture id as doc1

session alice
delete message id doc1

session bob
expect message deleted
expect not message from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}
```

MSC:
```text
msc DeleteByCapturedId;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage({body="doc", subject="Draft", priority=high});
  Server -> Bob : DeliverMessage({body="doc", subject="Draft", priority=high});

  Alice -> Server : DeleteMessage(id=doc1);

  condition FinalState(Message(id=doc1), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high)) = false;
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

Notes:
- `capture id as doc1` is treated as a local alias binding for the created protocol identity; MSC core has no separate construct for that binding.

## mutation by seeded id

DSL:
```text
scenario mutation by seeded id

given
private feed alice<->bob has messages
1 id "msg-123" as doc1 from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}

session alice
connect
auth

edit message id doc1 field subject "Draft v2"

session bob
connect
auth

expect message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 id "msg-123" as doc1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc MutationBySeededId;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : EditMessage(id=doc1, field=subject, value="Draft v2");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high));
endmsc;
```

Extensions used:
- `Seen`

## delete by seeded id

DSL:
```text
scenario delete by seeded id

given
private feed alice<->bob has messages
1 id "msg-123" as doc1 from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}

session alice
connect
auth

delete message id doc1

session bob
connect
auth

expect message deleted
expect not message from alice {
  body: "doc"
  subject: "Draft"
  priority: high
}
```

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 id "msg-123" as doc1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc DeleteBySeededId;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DeleteMessage(id=doc1);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  condition FinalState(Message(id=doc1), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high)) = false;
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## delete overrides later field edit

DSL:
```text
scenario delete overrides later field edit

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob {
  body: "doc"
  subject: "Draft"
  priority: high
}

session alice
delete message ref "doc"
edit message ref "doc" field subject "Draft v2"

session bob
expect message deleted
expect not message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

MSC:
```text
msc DeleteOverridesLaterFieldEdit;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage({body="doc", subject="Draft", priority=high});
  Server -> Bob : DeliverMessage({body="doc", subject="Draft", priority=high});

  Alice -> Server : DeleteMessage(ref="doc");
  Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2");

  condition FinalState(Message(ref="doc"), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high)) = false;
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## replay converges after delete and later field edit

DSL:
```text
scenario replay converges after delete and later field edit

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob {
  body: "doc"
  subject: "Draft"
  priority: high
}

session alice
delete message ref "doc"
edit message ref "doc" field subject "Draft v2"

session bob
query events peer alice after 0

expect message deleted
expect not message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

MSC:
```text
msc ReplayConvergesAfterDeleteAndLaterFieldEdit;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage({body="doc", subject="Draft", priority=high});
  Server -> Bob : DeliverMessage({body="doc", subject="Draft", priority=high});

  Alice -> Server : DeleteMessage(ref="doc");
  Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2");

  Bob -> Server : EventQuery(peer=alice, after=0);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition FinalState(Message(ref="doc"), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high)) = false;
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## structured payload survives home bootstrap

DSL:
```text
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

MSC:
```text
Preconditions:
- alice has bob in roster
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc StructuredPayloadSurvivesHomeBootstrap;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(...);
  condition HasSnapshot;

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high));
endmsc;
```

Extensions used:
- `HasSnapshot`
- `Seen`

## field edit survives home bootstrap

DSL:
```text
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

MSC:
```text
Preconditions:
- alice has bob in roster
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc FieldEditSurvivesHomeBootstrap;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(...);
  condition HasSnapshot;

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high));
endmsc;
```

Extensions used:
- `HasSnapshot`
- `Seen`

## delete hides structured payload after home bootstrap

DSL:
```text
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

MSC:
```text
Preconditions:
- alice has bob in roster
- private feed alice<->bob has message 1 from Alice with payload {body="doc", subject="Draft", priority=high}

msc DeleteHidesStructuredPayloadAfterHomeBootstrap;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : DeleteMessage(ref="doc");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(...);
  condition HasSnapshot;

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition FinalState(Message(ref="doc"), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft", priority=high)) = false;
endmsc;
```

Extensions used:
- `FinalState`
- `HasSnapshot`
- `Seen`
