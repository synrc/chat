# MSC-READ

## basic delivery

DSL:
```text
scenario basic delivery

session alice
connect alice@example.com
auth password "secret"

session bob
connect bob@example.com
auth password "secret"

session alice
send message to bob "hi"

session bob
expect message from alice body "hi"
```

MSC:
```text
msc BasicDelivery;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect(alice@example.com);
  Alice -> Server : Authenticate(password="secret");

  Bob -> Server : Connect(bob@example.com);
  Bob -> Server : Authenticate(password="secret");

  Alice -> Server : SendMessage("hi");
  Server -> Bob : DeliverMessage("hi");

  condition Seen(Message(from=Alice, body="hi"));
endmsc;
```

Extensions used:
- `Seen`

## delivery + read

DSL:
```text
scenario delivery + read

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "hi"

session bob
expect message from alice body "hi"

session bob
send read for last

session alice
expect message marked as read
```

MSC:
```text
msc DeliveryAndRead;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("hi");
  Server -> Bob : DeliverMessage("hi");

  condition Seen(Message(from=Alice, body="hi"));

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  condition Seen(MessageEvent(read, actor=Bob, seq=1));
endmsc;
```

Extensions used:
- `Seen`

## read cursor

DSL:
```text
scenario read cursor

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
expect message from alice body "m1"
expect message from alice body "m2"

session bob
send read for last

session bob
expect read cursor updated
```

MSC:
```text
msc ReadCursor;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Alice -> Server : SendMessage("m2");
  Server -> Bob : DeliverMessage("m2");

  condition Seen(Message(from=Alice, body="m1"));
  condition Seen(Message(from=Alice, body="m2"));

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=2);
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## cross-session read sync

DSL:
```text
scenario cross-session read sync

session bob1 as bob
connect
auth

session bob2 as bob
connect
auth

session alice
connect
auth

session alice
send message to bob "hi"

session bob1
send read for last

session bob2
expect read cursor updated
```

MSC:
```text
msc CrossSessionReadSync;
  instance Bob1;
  instance Bob2;
  instance Alice;
  instance Server;

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Bob2 -> Server : Connect();
  Bob2 -> Server : Authenticate(...);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SendMessage("hi");
  Server -> Bob1 : DeliverMessage("hi");
  Server -> Bob2 : DeliverMessage("hi");

  Bob1 -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=1);
endmsc;
```

Extensions used:
- `FinalState`

Notes:
- `bob1` and `bob2` are distinct sessions of the same user `bob`; the shared user-scoped semantics follows `session bob1 as bob` / `session bob2 as bob`.

## read backward rewinds cursor

DSL:
```text
scenario read backward rewinds cursor

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
expect message from alice body "m1"
expect message from alice body "m2"

session bob
query cursor read feed private:alice up to 2

session bob
expect read cursor updated

session bob
query cursor read feed private:alice up to 1

session bob
expect read cursor updated
```

MSC:
```text
msc ReadBackwardRewindsCursor;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Alice -> Server : SendMessage("m2");
  Server -> Bob : DeliverMessage("m2");

  condition Seen(Message(from=Alice, body="m1"));
  condition Seen(Message(from=Alice, body="m2"));

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);
  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=2);

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);
  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=1);
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## read after reconnect

DSL:
```text
scenario read after reconnect

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
expect message from alice body "m1"
expect message from alice body "m2"

session bob
disconnect
wait 500ms
reconnect

session bob
send read for last

session bob
expect read cursor updated
```

MSC:
```text
msc ReadAfterReconnect;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Alice -> Server : SendMessage("m2");
  Server -> Bob : DeliverMessage("m2");

  condition Seen(Message(from=Alice, body="m1"));
  condition Seen(Message(from=Alice, body="m2"));

  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=2);
endmsc;
```

Extensions used:
- `Delay(500ms)` (`extension (new)`)
- `FinalState`
- `Seen`

Notes:
- `wait 500ms` has no canonical mapping in `MSC-MAPPING-v2.md`, so it is represented as `extension (new)`.

## read wrong feed

DSL:
```text
scenario read wrong feed

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "hi"

session bob
expect message from alice body "hi"

session bob
query cursor read feed private:carol up to 1

session bob
expect error badRequest
```

MSC:
```text
msc ReadWrongFeed;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("hi");
  Server -> Bob : DeliverMessage("hi");

  condition Seen(Message(from=Alice, body="hi"));

  Bob -> Server : UpdateReadCursor(feed=private:carol, up_to=1);

  condition Error(badRequest);
endmsc;
```

Extensions used:
- `Error`
- `Seen`

## read before delivery

DSL:
```text
scenario read before delivery

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query cursor read feed private:alice up to 2

session bob
expect message from alice body "m1"
expect message from alice body "m2"

session alice
expect message marked as read
```

MSC:
```text
msc ReadBeforeDelivery;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Server -> Bob : DeliverMessage("m1");
  Server -> Bob : DeliverMessage("m2");

  condition Seen(Message(from=Alice, body="m1"));
  condition Seen(Message(from=Alice, body="m2"));
  condition Seen(MessageEvent(read, actor=Bob, seq=2));
endmsc;
```

Extensions used:
- `Seen`

## multi-feed read isolation

DSL:
```text
scenario multi-feed read isolation

session alice
connect
auth

session bob
connect
auth

session carol
connect
auth

session alice
create group room1
add bob to group room1
add carol to group room1

session alice
send message to bob "p1"

session carol
send message to group:room1 "g1"

session bob
expect message from alice body "p1"
expect message from carol body "g1"

session bob
send read group room1 for last

session bob
expect read cursor updated in group:room1
expect read cursor unchanged in private:alice
```

MSC:
```text
msc MultiFeedReadIsolation;
  instance Alice;
  instance Bob;
  instance Carol;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Carol -> Server : Connect();
  Carol -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : AddMember(room1, Carol);

  Alice -> Server : SendMessage(to=Bob, body="p1");
  Server -> Bob : DeliverMessage("p1");

  Carol -> Server : SendGroupMessage(room1, "g1");
  Server -> Bob : DeliverGroupMessage(room1, "g1");

  condition Seen(Message(from=Alice, body="p1"));
  condition Seen(Message(from=Carol, body="g1"));

  Bob -> Server : UpdateReadCursor(feed=group:room1, up_to=1);

  condition FinalState(ReadCursor(actor=Bob, feed=group:room1), up_to=1);
  condition NotChanged(ReadCursor(actor=Bob, feed=private:alice));
endmsc;
```

Extensions used:
- `FinalState`
- `NotChanged`
- `Seen`

## read persists after reconnect

DSL:
```text
scenario read persists after reconnect

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
query events peer alice after cursor

expect events non-empty

send read for last

disconnect
reconnect
auth resume

query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc ReadPersistsAfterReconnect;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Bob -> Server : Disconnect();
  Bob -> Server : Connect();
  Bob -> Server : Authenticate(resume);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultNotEmpty`
- `ReplayEmpty`

## replay respects read cursor

DSL:
```text
scenario replay respects read cursor

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor

expect events

send read for last

query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc ReplayRespectsReadCursor;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultNotEmpty`
- `ReplayEmpty`

## read is shared across sessions

DSL:
```text
scenario read is shared across sessions

session alice
connect
auth

session bob1 as bob
connect
auth

session bob2 as bob
connect
auth

session alice
send message to bob "m1"

session bob1
query events peer alice after cursor
send read for last

session bob2
query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc ReadIsSharedAcrossSessions;
  instance Alice;
  instance Bob1;
  instance Bob2;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob1 -> Server : Connect();
  Bob1 -> Server : Authenticate(...);

  Bob2 -> Server : Connect();
  Bob2 -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");

  Bob1 -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob1 : MessageEvent(...);
  endloop;

  Bob1 -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Bob2 -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ReplayEmpty`

Notes:
- `bob1` and `bob2` are distinct sessions of the same user `bob`; the shared user-scoped semantics follows `session bob1 as bob` / `session bob2 as bob`.

## unread does not change without read

DSL:
```text
scenario unread does not change without read

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor

expect events
```

MSC:
```text
msc UnreadDoesNotChangeWithoutRead;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `ResultNotEmpty`

## read clears unread boundary for current head

DSL:
```text
scenario read clears unread boundary for current head

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor
expect events

session bob
send read for last

session bob
query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc ReadClearsUnreadBoundaryForCurrentHead;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultNotEmpty`
- `ReplayEmpty`

## new message after read becomes unread again

DSL:
```text
scenario new message after read becomes unread again

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
query events peer alice after cursor
expect events

session bob
send read for last

session alice
send message to bob "m2"

session bob
query events peer alice after cursor

expect events non-empty
```

MSC:
```text
msc NewMessageAfterReadBecomesUnreadAgain;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `ResultNotEmpty`

## reconnect does not change unread

DSL:
```text
scenario reconnect does not change unread

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
disconnect
wait 500ms
reconnect
auth resume

session bob
query events peer alice after cursor

expect events non-empty
```

MSC:
```text
msc ReconnectDoesNotChangeUnread;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");

  Bob -> Server : Disconnect();
  condition Delay(500ms);
  Bob -> Server : Connect();
  Bob -> Server : Authenticate(resume);

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

## older history view does not change read cursor

DSL:
```text
scenario older history view does not change read cursor

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor
expect events

session bob
send read for last

session bob
query inbox peer alice

expect messages

session bob
query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc OlderHistoryViewDoesNotChangeReadCursor;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Bob -> Server : InboxQuery(peer=alice);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultNotEmpty`
- `ReplayEmpty`

## partial read keeps newer tail unread

DSL:
```text
scenario partial read keeps newer tail unread

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"
send message to bob "m3"

session bob
query events peer alice after cursor limit 1

expect events count <= 1
expect more

session bob
send read for last

session bob
query events peer alice after cursor

expect events non-empty
```

MSC:
```text
msc PartialReadKeepsNewerTailUnread;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");
  Alice -> Server : SendMessage("m3");

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=1);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 1;
  condition ResultNotEmpty;
  condition HasMore;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultCount`
- `ResultNotEmpty`

## read after partial replay advances only observed boundary

DSL:
```text
scenario read after partial replay advances only observed boundary

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"
send message to bob "m3"

session bob
query events peer alice after cursor limit 2

expect events count <= 2
expect more

session bob
send read for last

session bob
query events peer alice after cursor

expect events non-empty
expect not more
```

MSC:
```text
msc ReadAfterPartialReplayAdvancesOnlyObservedBoundary;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");
  Alice -> Server : SendMessage("m3");

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=2);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 2;
  condition ResultNotEmpty;
  condition HasMore;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultCount`
- `ResultNotEmpty`

## new message after partial read stays after unread boundary

DSL:
```text
scenario new message after partial read stays after unread boundary

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor limit 1

expect events count <= 1
expect more

session bob
send read for last

session alice
send message to bob "m3"

session bob
query events peer alice after cursor

expect events non-empty
```

MSC:
```text
msc NewMessageAfterPartialReadStaysAfterUnreadBoundary;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Alice -> Server : SendMessage("m2");

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=1);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 1;
  condition ResultNotEmpty;
  condition HasMore;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=1);

  Alice -> Server : SendMessage("m3");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `HasMore`
- `ResultCount`
- `ResultNotEmpty`
