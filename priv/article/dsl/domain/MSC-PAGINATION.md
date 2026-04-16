# MSC-PAGINATION

## inbox pagination

DSL:
```text
scenario inbox pagination

given
  private feed alice<->bob has messages
    1 from alice "p1"
    2 from bob "p2"
    3 from alice "p3"
    4 from bob "p4"
    5 from alice "p5"
    6 from bob "p6"
    7 from alice "p7"
    8 from bob "p8"
    9 from alice "p9"
    10 from bob "p10"
    11 from alice "p11"

session bob
connect
auth

query inbox peer alice limit 10

expect result items <= 10
expect more

query inbox continue

expect result items
```

MSC:
```text
Preconditions:
- private feed alice<->bob has messages 1..11

msc InboxPagination;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : InboxQuery(peer=alice, limit=10);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition ResultCount <= 10;
  condition HasMore;

  Bob -> Server : InboxQuery(continue);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultCount`
- `ResultNotEmpty`

## continue without initial query

DSL:
```text
scenario continue without initial query

session bob
connect
auth

query inbox continue

expect error badRequest
```

MSC:
```text
msc ContinueWithoutInitialQuery;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : InboxQuery(continue);

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## continue after feed change

DSL:
```text
scenario continue after feed change

session bob
connect
auth

query inbox peer alice limit 10
expect result items

query inbox peer carol continue

expect error badRequest
```

MSC:
```text
msc ContinueAfterFeedChange;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : InboxQuery(peer=alice, limit=10);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition ResultNotEmpty;

  Bob -> Server : InboxQuery(peer=carol, continue);

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`
- `ResultNotEmpty`

## empty page no more

DSL:
```text
scenario empty page no more

given
  private feed carol<->dave has messages
    1 from carol "x1"
    2 from dave "x2"
    3 from carol "x3"

session bob
connect
auth

query inbox peer alice limit 10

expect result items = 0
expect not more
```

MSC:
```text
Preconditions:
- private feed carol<->dave has messages 1..3

msc EmptyPageNoMore;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : InboxQuery(peer=alice, limit=10);

  condition ResultCount = 0;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultCount`

## home bootstrap pagination

DSL:
```text
scenario home bootstrap pagination

given
  bob has user1 in roster
  bob has user2 in roster
  bob has user3 in roster
  bob has user4 in roster
  bob has user5 in roster
  bob has user6 in roster
  bob has user7 in roster
  bob has user8 in roster
  bob has user9 in roster
  bob has user10 in roster
  bob has user11 in roster
  bob has user12 in roster

session bob
connect
auth

bootstrap home limit 10 preview 1

expect roster
expect feeds count <= 10
expect previews
expect shared snapshot
expect more

query home continue

expect feeds
```

MSC:
```text
Preconditions:
- bob has user1..user12 in roster

msc HomeBootstrapPagination;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(limit=10, preview=1);

  condition ResultNotEmpty;
  condition ResultCount <= 10;
  condition HasSnapshot;
  condition HasMore;

  Bob -> Server : HomeQuery(continue);

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `HasMore`
- `HasSnapshot`
- `ResultCount`
- `ResultNotEmpty`

Notes:
- `expect roster` and `expect previews` refer to composite home subresults; current correspondence fixes them only at the enclosing home-result level, without separate typed predicates.

## home continue without initial query

DSL:
```text
scenario home continue without initial query

session bob
connect
auth

query home continue

expect error badRequest
```

MSC:
```text
msc HomeContinueWithoutInitialQuery;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(continue);

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`

## home pagination no duplicate feeds

DSL:
```text
scenario home pagination no duplicate feeds

given
  bob has user1 in roster
  bob has user2 in roster
  bob has user3 in roster
  bob has user4 in roster
  bob has user5 in roster
  bob has user6 in roster
  bob has user7 in roster
  bob has user8 in roster
  bob has user9 in roster
  bob has user10 in roster
  bob has user11 in roster
  bob has user12 in roster

session bob
connect
auth

bootstrap home limit 10 preview 1

expect feeds
expect shared snapshot
expect more

query home continue

expect feeds
expect not duplicate feeds
```

MSC:
```text
Preconditions:
- bob has user1..user12 in roster

msc HomePaginationNoDuplicateFeeds;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(limit=10, preview=1);

  condition ResultNotEmpty;
  condition HasSnapshot;
  condition HasMore;

  Bob -> Server : HomeQuery(continue);

  condition ResultNotEmpty;
  condition NoDuplicates;
endmsc;
```

Extensions used:
- `HasMore`
- `HasSnapshot`
- `NoDuplicates`
- `ResultNotEmpty`

## empty home page no more

DSL:
```text
scenario empty home page no more

session bob
connect
auth

bootstrap home limit 10 preview 1

expect feeds count = 0
expect not more
```

MSC:
```text
msc EmptyHomePageNoMore;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(limit=10, preview=1);

  condition ResultCount = 0;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultCount`

## event streaming

DSL:
```text
scenario event streaming

given
  private feed alice<->bob has messages
    1 from alice "e1"
    2 from bob "e2"
    3 from alice "e3"
    4 from bob "e4"
    5 from alice "e5"
    6 from bob "e6"
    7 from alice "e7"
    8 from bob "e8"
    9 from alice "e9"
    10 from bob "e10"
    11 from alice "e11"
    12 from bob "e12"
    13 from alice "e13"
    14 from bob "e14"
    15 from alice "e15"
    16 from bob "e16"
    17 from alice "e17"
    18 from bob "e18"
    19 from alice "e19"
    20 from bob "e20"

session bob
connect
auth

query events peer alice after 10 limit 5

expect events count <= 5
expect next
expect more
```

MSC:
```text
Preconditions:
- private feed alice<->bob has messages 1..20

msc EventStreaming;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=10, limit=5);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 5;
  condition HasNext;
  condition HasMore;
endmsc;
```

Extensions used:
- `HasMore`
- `HasNext`
- `ResultCount`

## event replay pagination

DSL:
```text
scenario event replay pagination

given
  private feed alice<->bob has messages
    1 from alice "e1"
    2 from bob "e2"
    3 from alice "e3"
    4 from bob "e4"
    5 from alice "e5"
    6 from bob "e6"
    7 from alice "e7"
    8 from bob "e8"
    9 from alice "e9"
    10 from bob "e10"
    11 from alice "e11"
    12 from bob "e12"
    13 from alice "e13"
    14 from bob "e14"
    15 from alice "e15"
    16 from bob "e16"
    17 from alice "e17"
    18 from bob "e18"
    19 from alice "e19"
    20 from bob "e20"

session bob
connect
auth

query events peer alice after 10 limit 2

expect events count <= 2
expect next

query events peer alice after next

expect events
```

MSC:
```text
Preconditions:
- private feed alice<->bob has messages 1..20

msc EventReplayPagination;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=10, limit=2);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 2;
  condition HasNext;

  Bob -> Server : EventQuery(peer=alice, after=next);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `HasNext`
- `ResultCount`
- `ResultNotEmpty`

## replay no more

DSL:
```text
scenario replay no more

given
  private feed alice<->bob has messages
    1 from alice "z1"
    2 from bob "z2"
    3 from alice "z3"
  bob read private:alice up to 3

session bob
connect
auth

query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
Preconditions:
- private feed alice<->bob has messages 1..3
- bob read private:alice up to 3

msc ReplayNoMore;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ReplayEmpty`
