# MSC-HOME

## home returns feeds and snapshot after new message

DSL:
```text
scenario home returns feeds and snapshot after new message

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
bootstrap home

expect feeds
expect shared snapshot
expect feeds count <= 10
```

MSC:
```text
msc HomeReturnsFeedsAndSnapshotAfterNewMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition HasSnapshot;
  condition ResultCount <= 10;
endmsc;
```

Extensions used:
- `HasSnapshot`
- `ResultCount`
- `ResultNotEmpty`

## read does not break home bootstrap

DSL:
```text
scenario read does not break home bootstrap

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
query inbox peer alice
session bob
send read peer alice for last

session bob
bootstrap home

expect feeds
expect shared snapshot
```

MSC:
```text
msc ReadDoesNotBreakHomeBootstrap;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `HasSnapshot`
- `ResultNotEmpty`

## replay does not replace home snapshot

DSL:
```text
scenario replay does not replace home snapshot

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
query events peer alice after cursor

session bob
bootstrap home

expect feeds
expect shared snapshot
```

MSC:
```text
msc ReplayDoesNotReplaceHomeSnapshot;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `HasSnapshot`
- `ResultNotEmpty`

## home snapshot then replay preserves boundary

DSL:
```text
scenario home snapshot then replay preserves boundary

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
bootstrap home

session alice
send message to bob "m2"

session bob
query events peer alice after snapshot

expect events
expect no duplicates
expect no gaps
```

MSC:
```text
msc HomeSnapshotThenReplayPreservesBoundary;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : HomeQuery(...);

  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

## policy hides message from inbox-derived visibility

DSL:
```text
scenario policy hides message from inbox-derived visibility

given
message m1 has classification topsecret
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

MSC:
```text
Preconditions:
- message m1 has classification topsecret
- alice has clearance secret

msc PolicyHidesMessageFromInboxDerivedVisibility;
  instance Alice;
  instance Server;

  Alice -> Server : InboxQuery();

  condition Permitted(InboxQuery());
  condition Hidden(m1);
endmsc;
```

Extensions used:
- `Hidden`
- `Permitted(action)`

## home snapshot does not bypass later group moderation

DSL:
```text
scenario home snapshot does not bypass later group moderation

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session bob
bootstrap home

session alice
ban bob in group room1

session bob
query events group room1 after snapshot

expect error forbidden
```

MSC:
```text
msc HomeSnapshotDoesNotBypassLaterGroupModeration;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(...);

  Alice -> Server : BanInGroup(room1, Bob);

  Bob -> Server : EventQuery(group=room1, after=snapshot);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`
