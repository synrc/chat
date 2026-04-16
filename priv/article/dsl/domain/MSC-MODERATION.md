# MSC-MODERATION

## ban user

DSL:
```text
scenario ban user

session alice
connect
auth

ban bob

expect bob is banned
```

MSC:
```text
msc BanUser;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : Ban(Bob);

  condition FinalState(Moderation(scope=global), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`

## banned user cannot send direct message

DSL:
```text
scenario banned user cannot send direct message

session alice
connect
auth

session bob
connect
auth

session alice
ban bob

session bob
send message to alice "hi"

expect error forbidden
```

MSC:
```text
msc BannedUserCannotSendDirectMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : Ban(Bob);

  Bob -> Server : SendMessage("hi");

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## unban restores direct messaging

DSL:
```text
scenario unban restores direct messaging

session alice
connect
auth

session bob
connect
auth

session alice
ban bob
unban bob

session bob
send message to alice "hi"

session alice
expect message from bob body "hi"
```

MSC:
```text
msc UnbanRestoresDirectMessaging;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : Ban(Bob);
  Alice -> Server : Unban(Bob);

  Bob -> Server : SendMessage("hi");
  Server -> Alice : DeliverMessage("hi");

  condition Seen(Message(from=Bob, body="hi"));
endmsc;
```

Extensions used:
- `Seen`

## query moderation list

DSL:
```text
scenario query moderation list

session alice
connect
auth

ban bob
ban carol

query moderation

expect moderation
expect bob in moderation
expect carol in moderation
```

MSC:
```text
msc QueryModerationList;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : Ban(Bob);
  Alice -> Server : Ban(Carol);

  Alice -> Server : ModerationListQuery();

  condition ResultNotEmpty;
  condition FinalState(Moderation(scope=global), contains(Bob));
  condition FinalState(Moderation(scope=global), contains(Carol));
endmsc;
```

Extensions used:
- `FinalState`
- `ResultNotEmpty`

## moderation does not imply roster removal

DSL:
```text
scenario moderation does not imply roster removal

session alice
connect
auth

add bob to roster
ban bob

query roster

expect bob in roster
expect bob is banned
```

MSC:
```text
msc ModerationDoesNotImplyRosterRemoval;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);
  Alice -> Server : Ban(Bob);

  Alice -> Server : RosterQuery();

  condition FinalState(Roster(actor=Alice), contains(Bob));
  condition FinalState(Moderation(scope=global), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`

## moderation does not imply subscription removal

DSL:
```text
scenario moderation does not imply subscription removal

session alice
connect
auth

add bob to roster
ban bob

query subscriptions

expect subscriptions
expect bob in subscriptions
```

MSC:
```text
msc ModerationDoesNotImplySubscriptionRemoval;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);
  Alice -> Server : Ban(Bob);

  Alice -> Server : SubscriptionQuery();

  condition ResultNotEmpty;
  condition FinalState(Subscriptions(actor=Alice), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`
- `ResultNotEmpty`

## ban does not rewrite history

DSL:
```text
scenario ban does not rewrite history

session alice
connect
auth

session bob
connect
auth

session bob
send message to alice "m1"

session alice
ban bob

expect message from bob body "m1"
```

MSC:
```text
msc BanDoesNotRewriteHistory;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SendMessage("m1");
  Server -> Alice : DeliverMessage("m1");

  Alice -> Server : Ban(Bob);

  condition Seen(Message(from=Bob, body="m1"));
endmsc;
```

Extensions used:
- `Seen`

## ban blocks future messages only

DSL:
```text
scenario ban blocks future messages only

session alice
connect
auth

session bob
connect
auth

session bob
send message to alice "m1"

session alice
ban bob

session bob
send message to alice "m2"

expect error forbidden
```

MSC:
```text
msc BanBlocksFutureMessagesOnly;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SendMessage("m1");
  Server -> Alice : DeliverMessage("m1");

  Alice -> Server : Ban(Bob);

  Bob -> Server : SendMessage("m2");

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## ban user in group

DSL:
```text
scenario ban user in group

session alice
connect
auth

create group room1
add bob to group room1

ban bob in group room1

query moderation group room1

expect moderation
expect bob in moderation
expect bob is banned in group room1
```

MSC:
```text
msc BanUserInGroup;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Alice -> Server : BanInGroup(room1, Bob);

  Alice -> Server : ModerationListQuery(group=room1);

  condition ResultNotEmpty;
  condition FinalState(Moderation(scope=group:room1), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`
- `ResultNotEmpty`

## group ban blocks future group access

DSL:
```text
scenario group ban blocks future group access

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
query events group room1 after cursor

expect error forbidden
```

MSC:
```text
msc GroupBanBlocksFutureGroupAccess;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : BanInGroup(room1, Bob);

  Bob -> Server : EventQuery(group=room1, after=cursor);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## group ban does not imply global ban

DSL:
```text
scenario group ban does not imply global ban

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
send message to alice "hi"

session alice
expect message from bob body "hi"
```

MSC:
```text
msc GroupBanDoesNotImplyGlobalBan;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : BanInGroup(room1, Bob);

  Bob -> Server : SendMessage("hi");
  Server -> Alice : DeliverMessage("hi");

  condition Seen(Message(from=Bob, body="hi"));
endmsc;
```

Extensions used:
- `Seen`

## unban in group restores group access

DSL:
```text
scenario unban in group restores group access

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1
unban bob in group room1

session bob
query events group room1 after cursor

expect not error forbidden
```

MSC:
```text
msc UnbanInGroupRestoresGroupAccess;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : BanInGroup(room1, Bob);
  Alice -> Server : UnbanInGroup(room1, Bob);

  Bob -> Server : EventQuery(group=room1, after=cursor);

  condition Permitted(EventQuery(group=room1, after=cursor));
endmsc;
```

Extensions used:
- `Permitted(action)`

## group ban blocks inbox query

DSL:
```text
scenario group ban blocks inbox query

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
query inbox group room1

expect error forbidden
```

MSC:
```text
msc GroupBanBlocksInboxQuery;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : BanInGroup(room1, Bob);

  Bob -> Server : InboxQuery(group=room1);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## group ban blocks read update

DSL:
```text
scenario group ban blocks read update

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
query cursor read group room1 up to 1

expect error forbidden
```

MSC:
```text
msc GroupBanBlocksReadUpdate;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : BanInGroup(room1, Bob);

  Bob -> Server : UpdateReadCursor(feed=group:room1, up_to=1);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## group ban after home snapshot blocks later replay

DSL:
```text
scenario group ban after home snapshot blocks later replay

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
msc GroupBanAfterHomeSnapshotBlocksLaterReplay;
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

## group unban restores inbox access

DSL:
```text
scenario group unban restores inbox access

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1
unban bob in group room1

session bob
query inbox group room1

expect not error forbidden
```

MSC:
```text
msc GroupUnbanRestoresInboxAccess;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : BanInGroup(room1, Bob);
  Alice -> Server : UnbanInGroup(room1, Bob);

  Bob -> Server : InboxQuery(group=room1);

  condition Permitted(InboxQuery(group=room1));
endmsc;
```

Extensions used:
- `Permitted(action)`
