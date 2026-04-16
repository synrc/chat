# MSC-INVARIANTS

## Read cursor is not affected by global moderation

DSL:
```text
scenario read cursor is not affected by global moderation

given
  private feed alice<->bob has messages
    1 from alice "m1"
    2 from alice "m2"
  bob read private:alice up to 2

session bob
connect
auth

session alice
connect
auth

session alice
ban bob

session bob
query cursor read peer alice up to 2

expect read cursor unchanged
```

MSC:
```text
msc ReadCursorNotAffectedByGlobalModeration;
  instance Alice;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "m1"
    2 from alice "m2"
  - bob read private:alice up to 2

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : Ban(Bob);

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  condition NotChanged(ReadCursor(actor=Bob, feed=private:alice));
endmsc;
```

Extensions used:
- NotChanged

## ABAC view filtering does not change message truth

DSL:
```text
scenario ABAC view filtering does not change message truth

given
  message m1 has classification topsecret
  alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

MSC:
```text
msc AbacViewFilteringDoesNotChangeMessageTruth;
  instance Alice;
  instance Server;

  Preconditions:
  - message m1 has classification topsecret
  - alice has clearance secret

  Alice -> Server : InboxQuery();

  condition Permitted(InboxQuery());
  condition Hidden(m1);
endmsc;
```

Extensions used:
- Hidden
- Permitted(action)

## Group-scoped moderation overrides replay access

DSL:
```text
scenario group-scoped moderation overrides replay access

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1
  bob is banned in group room1
  group feed room1 has messages
    1 from alice "m1"

session bob
connect
auth

session bob
query events group room1 after cursor

expect error forbidden
```

MSC:
```text
msc GroupScopedModerationOverridesReplayAccess;
  instance Bob;
  instance Server;

  Preconditions:
  - group room1 exists
  - alice is owner of group room1
  - bob is member of group room1
  - bob is banned in group room1
  - group feed room1 has messages:
    1 from alice "m1"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(group=room1, after=cursor);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- Error(code)

## Snapshot does not bypass later group ban

DSL:
```text
scenario snapshot does not bypass later group ban

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
msc SnapshotDoesNotBypassLaterGroupBan;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : HomeQuery(...);
  condition HasSnapshot;

  Alice -> Server : BanInGroup(room1, Bob);

  Bob -> Server : EventQuery(group=room1, after=snapshot);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- Error(code)
- HasSnapshot

## Group moderation does not rewrite history

DSL:
```text
scenario group moderation does not rewrite history

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
send message to group:room1 "m1"
session bob
expect message from alice body "m1"

session alice
ban bob in group room1

session bob
expect message from alice body "m1"
```

MSC:
```text
msc GroupModerationDoesNotRewriteHistory;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendGroupMessage(room1, "m1");
  Server -> Bob : DeliverGroupMessage(room1, "m1");

  condition Seen(Message(from=Alice, body="m1"));

  Alice -> Server : BanInGroup(room1, Bob);

  condition Seen(Message(from=Alice, body="m1"));
endmsc;
```

Extensions used:
- Seen(Message(...))
