# MSC-GROUP

## create group

DSL:
```text
scenario create group

session alice
connect
auth

create group room1

expect group room1 exists
expect alice is owner of group room1
expect alice is member of group room1
```

MSC:
```text
msc CreateGroup;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);

  condition FinalState(Group(room1), exists);
  condition FinalState(GroupOwner(group=room1), Alice);
  condition FinalState(GroupMembers(group=room1), contains(Alice));
endmsc;
```

Extensions used:
- `FinalState`

## add member to group

DSL:
```text
scenario add member to group

session alice
connect
auth

create group room1

add bob to group room1

expect bob is member of group room1
```

MSC:
```text
msc AddMemberToGroup;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);

  Alice -> Server : AddMember(room1, Bob);

  condition FinalState(GroupMembers(group=room1), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`

## member can send message

DSL:
```text
scenario member can send message

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1

session bob
send message to group:room1 "hi"

session alice
expect message from bob body "hi"
```

MSC:
```text
msc MemberCanSendMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : SendGroupMessage(room1, "hi");
  Server -> Alice : DeliverGroupMessage(room1, "hi");

  condition Seen(Message(from=Bob, body="hi"));
endmsc;
```

Extensions used:
- `Seen`

## non-member cannot send message

DSL:
```text
scenario non-member cannot send message

session alice
connect
auth

session bob
connect
auth

session alice
create group room1

session bob
send message to group:room1 "hi"

expect error forbidden
```

MSC:
```text
msc NonMemberCannotSendMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);

  Bob -> Server : SendGroupMessage(room1, "hi");

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## member can query group inbox

DSL:
```text
scenario member can query group inbox

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1
send message to group:room1 "m1"

session bob
query inbox group room1

expect result items
```

MSC:
```text
msc MemberCanQueryGroupInbox;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : SendGroupMessage(room1, "m1");

  Bob -> Server : InboxQuery(group=room1);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- `ResultNotEmpty`

## non-member cannot query group inbox

DSL:
```text
scenario non-member cannot query group inbox

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
send message to group:room1 "m1"

session bob
query inbox group room1

expect error forbidden
```

MSC:
```text
msc NonMemberCannotQueryGroupInbox;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : SendGroupMessage(room1, "m1");

  Bob -> Server : InboxQuery(group=room1);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`

## removed member loses access

DSL:
```text
scenario removed member loses access

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1
send message to group:room1 "m1"

session bob
query inbox group room1
expect result items

session alice
remove bob from group room1

session bob
query inbox group room1

expect error forbidden
```

MSC:
```text
msc RemovedMemberLosesAccess;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : SendGroupMessage(room1, "m1");

  Bob -> Server : InboxQuery(group=room1);
  loop inbox_items
    Server -> Bob : Message(...);
  endloop;
  condition ResultNotEmpty;

  Alice -> Server : RemoveMember(room1, Bob);

  Bob -> Server : InboxQuery(group=room1);

  condition Error(forbidden);
endmsc;
```

Extensions used:
- `Error`
- `ResultNotEmpty`

## query group

DSL:
```text
scenario query group

session alice
connect
auth

create group room1

query group room1

expect group room1 exists
expect alice is owner of group room1
```

MSC:
```text
msc QueryGroup;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);

  Alice -> Server : GroupQuery(room1);

  condition FinalState(Group(room1), exists);
  condition FinalState(GroupOwner(group=room1), Alice);
endmsc;
```

Extensions used:
- `FinalState`

## query groups

DSL:
```text
scenario query groups

session alice
connect
auth

create group room1
create group room2

query groups

expect groups
expect room1 in groups
expect room2 in groups
```

MSC:
```text
msc QueryGroups;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : CreateGroup(room2);

  Alice -> Server : GroupListQuery();

  condition ResultNotEmpty;
  condition FinalState(GroupList(actor=Alice), contains(room1));
  condition FinalState(GroupList(actor=Alice), contains(room2));
endmsc;
```

Extensions used:
- `FinalState`
- `ResultNotEmpty`

## query members of group

DSL:
```text
scenario query members of group

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1

query members of group room1

expect members
expect alice is member of group room1
expect bob is member of group room1
```

MSC:
```text
msc QueryMembersOfGroup;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Alice -> Server : MemberListQuery(room1);

  condition ResultNotEmpty;
  condition FinalState(GroupMembers(group=room1), contains(Alice));
  condition FinalState(GroupMembers(group=room1), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`
- `ResultNotEmpty`

## delete group

DSL:
```text
scenario delete group

session alice
connect
auth

create group room1

delete group room1

query inbox group room1

expect error notFound
```

MSC:
```text
msc DeleteGroup;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);

  Alice -> Server : DeleteGroup(room1);

  condition FinalState(Group(room1), not_exists);

  Alice -> Server : InboxQuery(group=room1);

  condition Error(notFound);
endmsc;
```

Extensions used:
- `Error`
- `FinalState`
