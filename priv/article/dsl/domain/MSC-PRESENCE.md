# MSC-PRESENCE

## wildcard offline presence observation

DSL:
```text
scenario wildcard offline presence observation

session alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice
disconnect

session bob
query events peer alice after cursor

expect empty replay
expect event offline
```

MSC:
```text
msc WildcardOfflinePresenceObservation;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition Seen(PresenceEvent(offline));
endmsc;
```

Extensions used:
- `ReplayEmpty`
- `Seen`

## offline presence does not rewrite delivered message

DSL:
```text
scenario offline presence does not rewrite delivered message

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
query events peer alice after cursor

session alice
disconnect

session bob
query events peer alice after cursor

expect event offline alice
expect message from alice body "m1"
```

MSC:
```text
msc OfflinePresenceDoesNotRewriteDeliveredMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  condition Seen(Message(from=Alice, body="m1"));

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(offline, actor=Alice));
  condition Seen(Message(from=Alice, body="m1"));
endmsc;
```

Extensions used:
- `Seen`

## federated offline presence observation

DSL:
```text
scenario federated offline presence observation

session alice
connect brokerA
auth

session bob
connect brokerB
auth

session bob
query events peer alice after cursor

session alice
disconnect

session bob
query events peer alice after cursor

expect event offline alice
```

MSC:
```text
msc FederatedOfflinePresenceObservation;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect(brokerA);
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect(brokerB);
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(offline, actor=Alice));
endmsc;
```

Extensions used:
- `Seen`

## home snapshot does not replace presence observation

DSL:
```text
scenario home snapshot does not replace presence observation

session bob
connect
auth
add alice to roster

session alice
connect
auth

session bob
bootstrap home

expect feeds
expect shared snapshot

session alice
disconnect

session bob
query events peer alice after snapshot

expect empty replay
expect event offline alice
```

MSC:
```text
msc HomeSnapshotDoesNotReplacePresenceObservation;
  instance Bob;
  instance Server;
  instance Alice;

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);
  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(...);

  condition ResultNotEmpty;
  condition HasSnapshot;

  Alice -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=snapshot);

  condition ReplayEmpty;
  condition Seen(PresenceEvent(offline, actor=Alice));
endmsc;
```

Extensions used:
- `HasSnapshot`
- `ReplayEmpty`
- `ResultNotEmpty`
- `Seen`

## one of two sessions disconnects does not emit offline

DSL:
```text
scenario one of two sessions disconnects does not emit offline

session alice1 as alice
connect
auth

session alice2 as alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice1
disconnect

session bob
query events peer alice after cursor

expect empty replay
```

MSC:
```text
msc OneOfTwoSessionsDisconnectsDoesNotEmitOffline;
  instance Alice1;
  instance Alice2;
  instance Server;
  instance Bob;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice2 -> Server : Connect();
  Alice2 -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice1 -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
endmsc;
```

Extensions used:
- `ReplayEmpty`

Notes:
- `alice1` and `alice2` are distinct sessions of the same user `alice`; `offline` is user-scoped aggregate presence fact.

## last session disconnect emits offline

DSL:
```text
scenario last session disconnect emits offline

session alice1 as alice
connect
auth

session alice2 as alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice1
disconnect

session bob
query events peer alice after cursor
expect empty replay

session alice2
disconnect

session bob
query events peer alice after cursor

expect event offline alice
```

MSC:
```text
msc LastSessionDisconnectEmitsOffline;
  instance Alice1;
  instance Alice2;
  instance Server;
  instance Bob;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Alice2 -> Server : Connect();
  Alice2 -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice1 -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition ReplayEmpty;

  Alice2 -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(offline, actor=Alice));
endmsc;
```

Extensions used:
- `ReplayEmpty`
- `Seen`

Notes:
- `alice1` and `alice2` are distinct sessions of the same user `alice`; `offline` is emitted only after the last active session disappears.

## first session after offline emits online

DSL:
```text
scenario first session after offline emits online

session alice1 as alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice1
disconnect

session bob
query events peer alice after cursor
expect event offline alice

session alice2 as alice
connect
auth

session bob
query events peer alice after cursor

expect event online alice
```

MSC:
```text
msc FirstSessionAfterOfflineEmitsOnline;
  instance Alice1;
  instance Alice2;
  instance Server;
  instance Bob;

  Alice1 -> Server : Connect();
  Alice1 -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice1 -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition Seen(PresenceEvent(offline, actor=Alice));

  Alice2 -> Server : Connect();
  Alice2 -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(online, actor=Alice));
endmsc;
```

Extensions used:
- `Seen`

Notes:
- `alice1` and `alice2` are distinct sessions of the same user `alice`; `online` is emitted when the first session appears after fully-offline state.

## typing event is observable

DSL:
```text
scenario typing event is observable

session alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice
send typing to bob

session bob
query events peer alice after cursor

expect event typing alice
```

MSC:
```text
msc TypingEventIsObservable;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  Alice -> Server : SendTyping(Bob);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(typing, actor=Alice));
endmsc;
```

Extensions used:
- `Seen`

## typing does not imply read

DSL:
```text
scenario typing does not imply read

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

session alice
send typing to bob

session bob
query events peer alice after cursor

expect event typing alice
expect not error badRequest
```

MSC:
```text
msc TypingDoesNotImplyRead;
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

  Alice -> Server : SendTyping(Bob);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(typing, actor=Alice));
  condition Permitted(EventQuery(peer=alice, after=cursor));
endmsc;
```

Extensions used:
- `Permitted(action)`
- `Seen`

## typing does not survive replay or bootstrap as stable state

DSL:
```text
scenario typing does not survive replay or bootstrap as stable state

session alice
connect
auth

session bob
connect
auth

session alice
send typing to bob

session bob
query events peer alice after cursor
expect event typing alice

session bob
bootstrap home
expect feeds

session bob
query events peer alice after cursor
expect empty replay
```

MSC:
```text
msc TypingDoesNotSurviveReplayOrBootstrapAsStableState;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendTyping(Bob);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition Seen(PresenceEvent(typing, actor=Alice));

  Bob -> Server : HomeQuery(...);
  condition ResultNotEmpty;

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition ReplayEmpty;
endmsc;
```

Extensions used:
- `ReplayEmpty`
- `ResultNotEmpty`
- `Seen`
