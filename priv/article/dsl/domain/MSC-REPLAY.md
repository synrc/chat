# MSC-REPLAY

## replay

DSL:
```text
scenario replay

given
  private feed alice<->bob has messages
    1 from alice "hi"

session bob
connect
auth
disconnect
wait 500ms
reconnect

session bob
query events peer alice after cursor

expect events non-empty
```

MSC:
```text
Preconditions:
- private feed alice<->bob has message 1 from Alice with body "hi"

msc Replay;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `ResultNotEmpty`

Notes:
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## preview after reconnect

DSL:
```text
scenario preview after reconnect

given
  private feed alice<->bob has messages
    1 from alice "m1"
    2 from alice "m2"
    3 from alice "m3"

session bob
connect
auth
disconnect
wait 500ms
reconnect

session bob
query events peer alice after cursor limit 1

expect events count <= 1
expect more

send read for last
```

MSC:
```text
Preconditions:
- private feed alice<->bob has messages 1..3 from Alice

msc PreviewAfterReconnect;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=1);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 1;
  condition HasMore;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `HasMore`
- `ResultCount`

Notes:
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## home bootstrap after reconnect

DSL:
```text
scenario home bootstrap after reconnect

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
disconnect
wait 500ms
reconnect

bootstrap home limit 20 preview 1

expect roster
expect feeds
expect previews
expect shared snapshot
```

MSC:
```text
msc HomeBootstrapAfterReconnect;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : HomeQuery(limit=20, preview=1);

  condition ResultNotEmpty;
  condition HasSnapshot;
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `HasSnapshot`
- `ResultNotEmpty`

Notes:
- `expect roster` and `expect previews` refer to composite home subresults; current correspondence fixes them only at the enclosing home-result level.
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## home bootstrap then replay

DSL:
```text
scenario home bootstrap then replay

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
disconnect
wait 500ms
reconnect

bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

query events peer alice after snapshot

expect no duplicates
expect no gaps
```

MSC:
```text
msc HomeBootstrapThenReplay;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : HomeQuery(limit=20, preview=1);
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

Notes:
- `expect previews` refers to a composite home subresult; current correspondence fixes it only at the enclosing home-result level.
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## home bootstrap with concurrent message

DSL:
```text
scenario home bootstrap with concurrent message

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
disconnect
wait 500ms
reconnect

bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

session alice
send message to bob "m3"

session bob
query events peer alice after snapshot

expect no duplicates
expect no gaps
expect events
```

MSC:
```text
msc HomeBootstrapWithConcurrentMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : HomeQuery(limit=20, preview=1);
  condition ResultNotEmpty;
  condition HasSnapshot;

  Alice -> Server : SendMessage("m3");

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition NoDuplicates;
  condition NoGaps;
  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

Notes:
- `expect previews` refers to a composite home subresult; current correspondence fixes it only at the enclosing home-result level.
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## home bootstrap multi-feed replay

DSL:
```text
scenario home bootstrap multi-feed replay

session bob
connect
auth
add alice to roster

session alice
connect
auth
create group room1
add bob to group room1
send message to bob "p1"
send message to group:room1 "g1"

session bob
bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

query events feed private:alice after snapshot

expect no duplicates
expect no gaps

query events group room1 after snapshot

expect no duplicates
expect no gaps
```

MSC:
```text
msc HomeBootstrapMultiFeedReplay;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : SendMessage("p1");
  Alice -> Server : SendGroupMessage(room1, "g1");

  Bob -> Server : HomeQuery(limit=20, preview=1);
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(feed=private:alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition NoDuplicates;
  condition NoGaps;

  Bob -> Server : EventQuery(group=room1, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

Notes:
- `expect previews` refers to a composite home subresult; current correspondence fixes it only at the enclosing home-result level.

## replay with read race

DSL:
```text
scenario replay with read race

given
  private feed alice<->bob has messages
    1 from alice "m1"
    2 from alice "m2"
    3 from alice "m3"

session alice
connect
auth

session bob
connect
auth
disconnect
wait 500ms
reconnect

session bob
query events peer alice after cursor limit 2
expect events

session alice
send message to bob "m4"

session bob
send read for last

session bob
query events peer alice after next

expect events
expect no duplicates
```

MSC:
```text
Preconditions:
- private feed alice<->bob has messages 1..3 from Alice

msc ReplayWithReadRace;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=2);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Alice -> Server : SendMessage("m4");

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Bob -> Server : EventQuery(peer=alice, after=next);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
  condition NoDuplicates;
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `NoDuplicates`
- `ResultNotEmpty`

Notes:
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## duplicate event delivery

DSL:
```text
scenario duplicate event delivery

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
expect message from alice body "m1"

session bob
expect message from alice body "m1"

session bob
expect no duplicate side effects
```

MSC:
```text
msc DuplicateEventDelivery;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  condition Seen(Message(from=Alice, body="m1"));
  condition Seen(Message(from=Alice, body="m1"));
endmsc;
```

Extensions used:
- `Seen`

Notes:
- `expect no duplicate side effects` is not covered by an existing predicate in `MSC-MAPPING-v2.md` or `MSC-DSL-CORRESPONDENCE.md`; it cannot be represented more precisely without introducing a new extension.

## gap

DSL:
```text
scenario gap

session bob
connect
auth

query events peer alice after 0

expect error gap
```

MSC:
```text
msc Gap;
  instance Bob;
  instance Server;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=0);

  condition Error(gap);
endmsc;
```

Extensions used:
- `Error`

## gap recovery

DSL:
```text
scenario gap recovery

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth
send message to bob "m1"

session bob
query inbox peer alice
expect messages
```

MSC:
```text
msc GapRecovery;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=0);
  condition Error(gap);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : SendMessage("m1");

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `Error`
- `ResultNotEmpty`

## gap recovery with replay anchor

DSL:
```text
scenario gap recovery with replay anchor

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth
send message to bob "m1"

session bob
query inbox peer alice
expect messages
expect snapshot

query events peer alice after snapshot
```

MSC:
```text
msc GapRecoveryWithReplayAnchor;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=0);
  condition Error(gap);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : SendMessage("m1");

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
endmsc;
```

Extensions used:
- `Error`
- `HasSnapshot`
- `ResultNotEmpty`

## gap recovery with concurrent message

DSL:
```text
scenario gap recovery with concurrent message

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth

session alice
send message to bob "m3"

session bob
query inbox peer alice
expect messages
expect snapshot

session bob
query events peer alice after snapshot
expect no duplicates
expect no gaps
```

MSC:
```text
msc GapRecoveryWithConcurrentMessage;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=0);
  condition Error(gap);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : SendMessage("m3");

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `Error`
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

## paged snapshot recovery

DSL:
```text
scenario paged snapshot recovery

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth
send message to bob "m1"
send message to bob "m2"
send message to bob "m3"
send message to bob "m4"
send message to bob "m5"
send message to bob "m6"
send message to bob "m7"
send message to bob "m8"
send message to bob "m9"
send message to bob "m10"
send message to bob "m11"

session bob
query inbox peer alice limit 10
expect messages
expect snapshot
expect more

query inbox continue
expect messages

query events peer alice after snapshot
expect no duplicates
expect no gaps
```

MSC:
```text
msc PagedSnapshotRecovery;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=0);
  condition Error(gap);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");
  Alice -> Server : SendMessage("m3");
  Alice -> Server : SendMessage("m4");
  Alice -> Server : SendMessage("m5");
  Alice -> Server : SendMessage("m6");
  Alice -> Server : SendMessage("m7");
  Alice -> Server : SendMessage("m8");
  Alice -> Server : SendMessage("m9");
  Alice -> Server : SendMessage("m10");
  Alice -> Server : SendMessage("m11");

  Bob -> Server : InboxQuery(peer=alice, limit=10);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;
  condition HasSnapshot;
  condition HasMore;

  Bob -> Server : InboxQuery(continue);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `Error`
- `HasMore`
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

## multi-feed snapshot isolation

DSL:
```text
scenario multi-feed snapshot isolation

session bob
connect
auth

session alice
connect
auth
create group room1
add bob to group room1
send message to bob "p1"
send message to group:room1 "g1"

session bob
query events feed private:alice after 0
expect error gap

query events group room1 after 0
expect error gap

query inbox feed private:alice
expect messages
expect snapshot

query inbox group room1
expect messages
expect snapshot

query events feed private:alice after snapshot
expect no duplicates
expect no gaps

query events group room1 after snapshot
expect no duplicates
expect no gaps
```

MSC:
```text
msc MultiFeedSnapshotIsolation;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : SendMessage("p1");
  Alice -> Server : SendGroupMessage(room1, "g1");

  Bob -> Server : EventQuery(feed=private:alice, after=0);
  condition Error(gap);

  Bob -> Server : EventQuery(group=room1, after=0);
  condition Error(gap);

  Bob -> Server : InboxQuery(feed=private:alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : InboxQuery(group=room1);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(feed=private:alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition NoDuplicates;
  condition NoGaps;

  Bob -> Server : EventQuery(group=room1, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `Error`
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`

## home snapshot is consistent across feeds

DSL:
```text
scenario home snapshot is consistent across feeds

session bob
connect
auth
add alice to roster

session alice
connect
auth
create group room1
add bob to group room1
send message to bob "p1"
send message to group:room1 "g1"

session bob
bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

query events feed private:alice after snapshot
expect no gaps

query events group room1 after snapshot
expect no gaps
```

MSC:
```text
msc HomeSnapshotIsConsistentAcrossFeeds;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : SendMessage("p1");
  Alice -> Server : SendGroupMessage(room1, "g1");

  Bob -> Server : HomeQuery(limit=20, preview=1);
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(feed=private:alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition NoGaps;

  Bob -> Server : EventQuery(group=room1, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition NoGaps;
endmsc;
```

Extensions used:
- `HasSnapshot`
- `NoGaps`
- `ResultNotEmpty`

Notes:
- `expect previews` refers to a composite home subresult; current correspondence fixes it only at the enclosing home-result level.

## home bootstrap does not affect read cursor

DSL:
```text
scenario home bootstrap does not affect read cursor

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor
expect events

send read for last

bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc HomeBootstrapDoesNotAffectReadCursor;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Bob -> Server : HomeQuery(limit=20, preview=1);
  condition ResultNotEmpty;
  condition HasSnapshot;

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `HasSnapshot`
- `ReplayEmpty`
- `ResultNotEmpty`

Notes:
- `expect previews` refers to a composite home subresult; current correspondence fixes it only at the enclosing home-result level.

## home continue preserves shared snapshot

DSL:
```text
scenario home continue preserves shared snapshot

session bob
connect
auth
add alice to roster
add carol to roster
add dave to roster
add erin to roster
add frank to roster
add grace to roster
add heidi to roster
add ivan to roster
add judy to roster
add mallory to roster
add niaj to roster

session alice
connect
auth
send message to bob "m1"

session bob
bootstrap home limit 10 preview 1

expect feeds
expect shared snapshot
expect more

query home continue

expect feeds
expect shared snapshot
expect not duplicate feeds

query events peer alice after snapshot

expect no duplicates
expect no gaps
```

MSC:
```text
msc HomeContinuePreservesSharedSnapshot;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);
  Bob -> Server : AddToRoster(Carol);
  Bob -> Server : AddToRoster(Dave);
  Bob -> Server : AddToRoster(Erin);
  Bob -> Server : AddToRoster(Frank);
  Bob -> Server : AddToRoster(Grace);
  Bob -> Server : AddToRoster(Heidi);
  Bob -> Server : AddToRoster(Ivan);
  Bob -> Server : AddToRoster(Judy);
  Bob -> Server : AddToRoster(Mallory);
  Bob -> Server : AddToRoster(Niaj);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);
  Alice -> Server : SendMessage("m1");

  Bob -> Server : HomeQuery(limit=10, preview=1);
  condition ResultNotEmpty;
  condition HasSnapshot;
  condition HasMore;

  Bob -> Server : HomeQuery(continue);
  condition ResultNotEmpty;
  condition HasSnapshot;
  condition NoDuplicates;

  Bob -> Server : EventQuery(peer=alice, after=snapshot);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition NoDuplicates;
  condition NoGaps;
endmsc;
```

Extensions used:
- `HasMore`
- `HasSnapshot`
- `NoDuplicates`
- `NoGaps`
- `ResultNotEmpty`
