# MSC-VISIBILITY

## message is hidden when clearance is insufficient

DSL:
```text
scenario message is hidden when clearance is insufficient

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

msc MessageIsHiddenWhenClearanceIsInsufficient;
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

## message is visible when clearance matches

DSL:
```text
scenario message is visible when clearance matches

given
message m1 has classification confidential
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 visible
```

MSC:
```text
Preconditions:
- message m1 has classification confidential
- alice has clearance secret

msc MessageIsVisibleWhenClearanceMatches;
  instance Alice;
  instance Server;

  Alice -> Server : InboxQuery();

  condition Permitted(InboxQuery());
  condition Visible(m1);
endmsc;
```

Extensions used:
- `Permitted(action)`
- `Visible`

## field visibility may be stricter than message visibility

DSL:
```text
scenario field visibility may be stricter than message visibility

given
message m1 has classification confidential
message m1 field body visible at level confidential
message m1 field attachment visible at level topsecret
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 visible
expect message m1 field body visible
expect message m1 field attachment hidden
```

MSC:
```text
Preconditions:
- message m1 has classification confidential
- message m1 field body visible at level confidential
- message m1 field attachment visible at level topsecret
- alice has clearance secret

msc FieldVisibilityMayBeStricterThanMessageVisibility;
  instance Alice;
  instance Server;

  Alice -> Server : InboxQuery();

  condition Permitted(InboxQuery());
  condition Visible(m1);
  condition FieldVisible(m1, body);
  condition FieldHidden(m1, attachment);
endmsc;
```

Extensions used:
- `FieldHidden`
- `FieldVisible`
- `Permitted(action)`
- `Visible`

## access denied does not imply hidden for already classifiable view

DSL:
```text
scenario access denied does not imply hidden for already classifiable view

given
message m1 has classification confidential
alice has clearance secret
alice is banned

when alice queries inbox

expect access denied
expect message m1 visible
```

MSC:
```text
Preconditions:
- message m1 has classification confidential
- alice has clearance secret
- alice is banned

msc AccessDeniedDoesNotImplyHiddenForAlreadyClassifiableView;
  instance Alice;
  instance Server;

  Alice -> Server : InboxQuery();

  condition Forbidden(InboxQuery());
  condition Visible(m1);
endmsc;
```

Extensions used:
- `Forbidden(action)`
- `Visible`

## hidden and deleted are different states

DSL:
```text
scenario hidden and deleted are different states

given
message m1 has classification topsecret
alice has clearance secret

session alice
connect
auth

session bob
connect
auth

session bob
send message to alice "x"
session bob
delete message "x"

session alice
expect message deleted

when alice queries inbox

expect access allowed
expect message m1 hidden
```

MSC:
```text
Preconditions:
- message m1 has classification topsecret
- alice has clearance secret

msc HiddenAndDeletedAreDifferentStates;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SendMessage("x");
  Server -> Alice : DeliverMessage("x");

  Bob -> Server : DeleteMessage("x");

  condition FinalState(Message(body="x"), deleted);

  Alice -> Server : InboxQuery();

  condition Permitted(InboxQuery());
  condition Hidden(m1);
endmsc;
```

Extensions used:
- `FinalState`
- `Hidden`
- `Permitted(action)`
