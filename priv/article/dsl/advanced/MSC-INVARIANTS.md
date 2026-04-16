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

  Bob -> Server : ReadCursorQuery(feed=private:alice);

  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=2);
endmsc;
```

Extensions used:
- FinalState(target, state)

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

  condition Permitted(action);
  condition Hidden(m1);
endmsc;
```

Extensions used:
- Hidden
- Permitted(action)

## Delete overrides visibility and replay

DSL:
```text
scenario delete overrides visibility and replay

given
  message m1 exists
  message m1 is visible to alice

session alice
connect
auth

session alice
delete message id m1

session alice
query events peer bob after cursor

expect message deleted
expect message m1 hidden
expect not message from bob body "m1"
```

MSC:
```text
msc DeleteOverridesVisibilityAndReplay;
  instance Alice;
  instance Server;

  Preconditions:
  - message m1 exists
  - message m1 is visible to alice

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DeleteMessage(id=m1);

  Alice -> Server : EventQuery(peer=bob, after=cursor);

  condition FinalState(Message(id=m1), deleted);
  condition Hidden(m1);
  condition Seen(Message(id=m1)) = false;
endmsc;
```

Extensions used:
- FinalState(target, state)
- Hidden
- Seen(Message(...)) = false

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
