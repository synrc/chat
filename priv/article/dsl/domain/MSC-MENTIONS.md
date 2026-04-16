# MSC-MENTIONS

## mention appears in home after incoming mention message

DSL:
```text
scenario mention appears in home after incoming mention message

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob {
body: "hi"
mention: bob
}

session bob
bootstrap home

expect feeds
expect mentions
expect shared snapshot
```

MSC:
```text
msc MentionAppearsInHomeAfterIncomingMentionMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage({body="hi", mentions=[Bob]});
  Server -> Bob : DeliverMessage({body="hi", mentions=[Bob]});

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition FinalState(Mentions(actor=Bob), present);
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `FinalState`
- `HasSnapshot`
- `ResultNotEmpty`

## read clears mention when mention boundary is covered

DSL:
```text
scenario read clears mention when mention boundary is covered

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob {
body: "hi"
mention: bob
}

session bob
query inbox peer alice
session bob
send read peer alice for last

session bob
bootstrap home

expect feeds
expect not mentions
expect shared snapshot
```

MSC:
```text
msc ReadClearsMentionWhenMentionBoundaryIsCovered;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage({body="hi", mentions=[Bob]});
  Server -> Bob : DeliverMessage({body="hi", mentions=[Bob]});

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition FinalState(Mentions(actor=Bob), absent);
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `FinalState`
- `HasSnapshot`
- `ResultNotEmpty`

## replay alone does not clear mention state

DSL:
```text
scenario replay alone does not clear mention state

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob {
body: "hi"
mention: bob
}

session bob
query events peer alice after cursor

session bob
bootstrap home

expect feeds
expect mentions
expect shared snapshot
```

MSC:
```text
msc ReplayAloneDoesNotClearMentionState;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage({body="hi", mentions=[Bob]});
  Server -> Bob : DeliverMessage({body="hi", mentions=[Bob]});

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition FinalState(Mentions(actor=Bob), present);
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `FinalState`
- `HasSnapshot`
- `ResultNotEmpty`

## hidden message does not produce visible mention state

DSL:
```text
scenario hidden message does not produce visible mention state

given
alice has clearance secret
message m1 has classification topsecret
message m1 field body visible at level topsecret
message m1 field mention visible at level topsecret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

MSC:
```text
Preconditions:
- alice has clearance secret
- message m1 has classification topsecret
- message m1 field body visible at level topsecret
- message m1 field mention visible at level topsecret

msc HiddenMessageDoesNotProduceVisibleMentionState;
  instance Alice;
  instance Server;

  Alice -> Server : InboxQuery();

  condition Permitted(InboxQuery());
  condition Hidden(m1);
  condition FinalState(Mentions(actor=Alice), absent);
endmsc;
```

Extensions used:
- `FinalState`
- `Hidden`
- `Permitted(action)`

## mention and unread are related but not identical

DSL:
```text
scenario mention and unread are related but not identical

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "plain"
session alice
send message to bob {
body: "important"
mention: bob
}

session bob
bootstrap home

expect feeds
expect mentions
expect shared snapshot
```

MSC:
```text
msc MentionAndUnreadAreRelatedButNotIdentical;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("plain");
  Server -> Bob : DeliverMessage("plain");

  Alice -> Server : SendMessage({body="important", mentions=[Bob]});
  Server -> Bob : DeliverMessage({body="important", mentions=[Bob]});

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition FinalState(Mentions(actor=Bob), present);
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `FinalState`
- `HasSnapshot`
- `ResultNotEmpty`
