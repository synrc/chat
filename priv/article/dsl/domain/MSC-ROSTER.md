# MSC-ROSTER

## add to roster

DSL:
```text
scenario add to roster

session alice
connect
auth

add bob to roster

query roster

expect bob in roster
```

MSC:
```text
msc AddToRoster;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);

  Alice -> Server : RosterQuery();

  condition FinalState(Roster(actor=Alice), contains(Bob));
endmsc;
```

Extensions used:
- `FinalState`

## remove from roster

DSL:
```text
scenario remove from roster

session alice
connect
auth

add bob to roster
query roster
expect bob in roster

remove bob from roster

query roster

expect bob not in roster
```

MSC:
```text
msc RemoveFromRoster;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);
  Alice -> Server : RosterQuery();
  condition FinalState(Roster(actor=Alice), contains(Bob));

  Alice -> Server : RemoveFromRoster(Bob);

  Alice -> Server : RosterQuery();

  condition FinalState(Roster(actor=Alice), excludes(Bob));
endmsc;
```

Extensions used:
- `FinalState`

## direct message without roster

DSL:
```text
scenario direct message without roster

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

session alice
query roster

expect bob not in roster
```

MSC:
```text
msc DirectMessageWithoutRoster;
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

  Alice -> Server : RosterQuery();

  condition FinalState(Roster(actor=Alice), excludes(Bob));
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`

## roster is not changed by direct message

DSL:
```text
scenario roster is not changed by direct message

session alice
connect
auth

session bob
connect
auth

session alice
query roster

session alice
send message to bob "ping"

session bob
expect message from alice body "ping"

session alice
query roster

expect bob not in roster
```

MSC:
```text
msc RosterIsNotChangedByDirectMessage;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : RosterQuery();

  Alice -> Server : SendMessage("ping");
  Server -> Bob : DeliverMessage("ping");

  condition Seen(Message(from=Alice, body="ping"));

  Alice -> Server : RosterQuery();

  condition NotChanged(Roster(actor=Alice));
  condition FinalState(Roster(actor=Alice), excludes(Bob));
endmsc;
```

Extensions used:
- `FinalState`
- `NotChanged`
- `Seen`

## mutual relation

DSL:
```text
scenario mutual relation

session alice
connect
auth

session bob
connect
auth

session alice
add bob to roster

session bob
add alice to roster

session alice
query roster
expect bob in roster

session bob
query roster
expect alice in roster
```

MSC:
```text
msc MutualRelation;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);

  Bob -> Server : AddToRoster(Alice);

  Alice -> Server : RosterQuery();
  condition FinalState(Roster(actor=Alice), contains(Bob));

  Bob -> Server : RosterQuery();
  condition FinalState(Roster(actor=Bob), contains(Alice));
endmsc;
```

Extensions used:
- `FinalState`

## one-way relation

DSL:
```text
scenario one-way relation

session alice
connect
auth

session bob
connect
auth

session alice
add bob to roster

session alice
query roster
expect bob in roster

session bob
query roster
expect alice not in roster
```

MSC:
```text
msc OneWayRelation;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);

  Alice -> Server : RosterQuery();
  condition FinalState(Roster(actor=Alice), contains(Bob));

  Bob -> Server : RosterQuery();
  condition FinalState(Roster(actor=Bob), excludes(Alice));
endmsc;
```

Extensions used:
- `FinalState`

## messaging after remove from roster

DSL:
```text
scenario messaging after remove from roster

session alice
connect
auth

session bob
connect
auth

session alice
add bob to roster
query roster
expect bob in roster

remove bob from roster

query roster
expect bob not in roster

session alice
send message to bob "hi after remove"

session bob
expect message from alice body "hi after remove"
```

MSC:
```text
msc MessagingAfterRemoveFromRoster;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);
  Alice -> Server : RosterQuery();
  condition FinalState(Roster(actor=Alice), contains(Bob));

  Alice -> Server : RemoveFromRoster(Bob);

  Alice -> Server : RosterQuery();
  condition FinalState(Roster(actor=Alice), excludes(Bob));

  Alice -> Server : SendMessage("hi after remove");
  Server -> Bob : DeliverMessage("hi after remove");

  condition Seen(Message(from=Alice, body="hi after remove"));
endmsc;
```

Extensions used:
- `FinalState`
- `Seen`
