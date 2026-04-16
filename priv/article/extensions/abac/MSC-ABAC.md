# MSC-ABAC

## Send allowed by clearance

DSL:
```text
scenario send allowed by clearance

given alice has clearance secret
given message m1 has classification confidential

when alice sends message

expect access allowed
```

MSC:
```text
msc SendAllowedByClearance;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - message m1 has classification confidential

  Alice -> Server : SendMessage(...);

  condition Permitted(action);
endmsc;
```

Extensions used:
- Permitted(action)

## Send denied by clearance

DSL:
```text
scenario send denied by clearance

given alice has clearance confidential
given message m1 has classification secret

when alice sends message

expect access denied
```

MSC:
```text
msc SendDeniedByClearance;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance confidential
  - message m1 has classification secret

  Alice -> Server : SendMessage(...);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Query events denied by branch policy

DSL:
```text
scenario query events denied by branch policy

given alice has branch civil
given feed room1 has branch military

when alice queries events for group room1

expect access denied
```

MSC:
```text
msc QueryEventsDeniedByBranchPolicy;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch civil
  - feed room1 has branch military

  Alice -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Query filters restricted messages

DSL:
```text
scenario query filters restricted messages

given alice has clearance confidential
given message m1 has classification confidential
given message m2 has classification secret

when alice queries inbox

expect message m1 visible
expect message m2 hidden
```

MSC:
```text
msc QueryFiltersRestrictedMessages;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance confidential
  - message m1 has classification confidential
  - message m2 has classification secret

  Alice -> Server : InboxQuery();

  condition Visible(m1);
  condition Hidden(m2);
endmsc;
```

Extensions used:
- Hidden
- Visible

## Payload field filtered by policy

DSL:
```text
scenario payload field filtered by policy

given alice has clearance confidential
given message m1 has classification secret
given message m1 field body visible at level confidential
given message m1 field attachment visible at level secret

when alice queries inbox

expect message m1 field body visible
expect message m1 field attachment hidden
```

MSC:
```text
msc PayloadFieldFilteredByPolicy;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance confidential
  - message m1 has classification secret
  - message m1 field body visible at level confidential
  - message m1 field attachment visible at level secret

  Alice -> Server : InboxQuery();

  condition FieldVisible(m1, body);
  condition FieldHidden(m1, attachment);
endmsc;
```

Extensions used:
- FieldHidden(x, field)
- FieldVisible(x, field)

## Send denied without clearance

DSL:
```text
scenario send denied without clearance

given message m1 has classification confidential

when alice sends message

expect access denied
```

MSC:
```text
msc SendDeniedWithoutClearance;
  instance Alice;
  instance Server;

  Preconditions:
  - message m1 has classification confidential

  Alice -> Server : SendMessage(...);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Send allowed on exact clearance boundary

DSL:
```text
scenario send allowed on exact clearance boundary

given alice has clearance secret
given message m1 has classification secret

when alice sends message

expect access allowed
```

MSC:
```text
msc SendAllowedOnExactClearanceBoundary;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - message m1 has classification secret

  Alice -> Server : SendMessage(...);

  condition Permitted(action);
endmsc;
```

Extensions used:
- Permitted(action)

## Query hides all restricted messages

DSL:
```text
scenario query hides all restricted messages

given alice has clearance confidential
given message m1 has classification secret
given message m2 has classification secret

when alice queries inbox

expect message m1 hidden
expect message m2 hidden
```

MSC:
```text
msc QueryHidesAllRestrictedMessages;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance confidential
  - message m1 has classification secret
  - message m2 has classification secret

  Alice -> Server : InboxQuery();

  condition Hidden(m1);
  condition Hidden(m2);
endmsc;
```

Extensions used:
- Hidden

## Field visibility differs inside one message

DSL:
```text
scenario field visibility differs inside one message

given alice has clearance confidential
given message m1 field body visible at level confidential
given message m1 field attachment visible at level secret
given message m1 field metadata visible at level confidential

when alice queries inbox

expect message m1 field body visible
expect message m1 field metadata visible
expect message m1 field attachment hidden
```

MSC:
```text
msc FieldVisibilityDiffersInsideOneMessage;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance confidential
  - message m1 field body visible at level confidential
  - message m1 field attachment visible at level secret
  - message m1 field metadata visible at level confidential

  Alice -> Server : InboxQuery();

  condition FieldVisible(m1, body);
  condition FieldVisible(m1, metadata);
  condition FieldHidden(m1, attachment);
endmsc;
```

Extensions used:
- FieldHidden(x, field)
- FieldVisible(x, field)

## Ban overrides clearance allow

DSL:
```text
scenario ban overrides clearance allow

given alice has clearance secret
given message m1 has classification confidential
given bob is banned

when bob sends message

expect access denied
```

MSC:
```text
msc BanOverridesClearanceAllow;
  instance Bob;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - message m1 has classification confidential
  - bob is banned

  Bob -> Server : SendMessage(...);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Ban blocks query even if attributes match

DSL:
```text
scenario ban blocks query even if attributes match

given alice has clearance secret
given bob is banned

when bob queries inbox

expect access denied
```

MSC:
```text
msc BanBlocksQueryEvenIfAttributesMatch;
  instance Bob;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - bob is banned

  Bob -> Server : InboxQuery();

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Remove member restricts group access

DSL:
```text
scenario remove member restricts group access

given alice has branch military
given feed room1 has branch military
given bob is not member of group room1

when bob queries events for group room1

expect access denied
```

MSC:
```text
msc RemoveMemberRestrictsGroupAccess;
  instance Bob;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military
  - bob is not member of group room1

  Bob -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Membership allows access when attributes match

DSL:
```text
scenario membership allows access when attributes match

given alice has branch military
given feed room1 has branch military
given alice is member of group room1

when alice queries events for group room1

expect access allowed
```

MSC:
```text
msc MembershipAllowsAccessWhenAttributesMatch;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military
  - alice is member of group room1

  Alice -> Server : EventQuery(group=room1);

  condition Permitted(action);
endmsc;
```

Extensions used:
- Permitted(action)

## Ban does not hide already visible messages

DSL:
```text
scenario ban does not hide already visible messages

given alice has clearance secret
given message m1 has classification confidential
given message m1 was visible to bob before ban
given bob is banned

when bob queries inbox

expect message m1 visible
```

MSC:
```text
msc BanDoesNotHideAlreadyVisibleMessages;
  instance Bob;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - message m1 has classification confidential
  - message m1 was visible to bob before ban
  - bob is banned

  Bob -> Server : InboxQuery();

  condition Visible(m1);
endmsc;
```

Extensions used:
- Visible

## Deny overrides allow from another rule

DSL:
```text
scenario deny overrides allow from another rule

given alice has clearance secret
given alice is banned
given message m1 has classification confidential

when alice sends message

expect access denied
```

MSC:
```text
msc DenyOverridesAllowFromAnotherRule;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - alice is banned
  - message m1 has classification confidential

  Alice -> Server : SendMessage(...);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Group membership does not override global ban

DSL:
```text
scenario group membership does not override global ban

given alice has branch military
given feed room1 has branch military
given alice is member of group room1
given alice is banned

when alice queries events for group room1

expect access denied
```

MSC:
```text
msc GroupMembershipDoesNotOverrideGlobalBan;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military
  - alice is member of group room1
  - alice is banned

  Alice -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Missing membership denies even with matching branch

DSL:
```text
scenario missing membership denies even with matching branch

given alice has branch military
given feed room1 has branch military

when alice queries events for group room1

expect access denied
```

MSC:
```text
msc MissingMembershipDeniesEvenWithMatchingBranch;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military

  Alice -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Allowed query may still hide part of result

DSL:
```text
scenario allowed query may still hide part of result

given alice has clearance secret
given message m1 has classification confidential
given message m2 has classification topsecret

when alice queries inbox

expect message m1 visible
expect message m2 hidden
```

MSC:
```text
msc AllowedQueryMayStillHidePartOfResult;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - message m1 has classification confidential
  - message m2 has classification topsecret

  Alice -> Server : InboxQuery();

  condition Visible(m1);
  condition Hidden(m2);
endmsc;
```

Extensions used:
- Hidden
- Visible

## Group-scoped ban blocks group query

DSL:
```text
scenario group-scoped ban blocks group query

given alice has branch military
given feed room1 has branch military
given alice is member of group room1
given alice is banned in group room1

when alice queries events for group room1

expect access denied
```

MSC:
```text
msc GroupScopedBanBlocksGroupQuery;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military
  - alice is member of group room1
  - alice is banned in group room1

  Alice -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Group-scoped ban does not imply global ban

DSL:
```text
scenario group-scoped ban does not imply global ban

given alice has clearance secret
given message m1 has classification confidential
given alice is banned in group room1

when alice sends message

expect access allowed
```

MSC:
```text
msc GroupScopedBanDoesNotImplyGlobalBan;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance secret
  - message m1 has classification confidential
  - alice is banned in group room1

  Alice -> Server : SendMessage(...);

  condition Permitted(action);
endmsc;
```

Extensions used:
- Permitted(action)

## Group-scoped ban does not remove membership

DSL:
```text
scenario group-scoped ban does not remove membership

given alice has branch military
given feed room1 has branch military
given alice is member of group room1
given alice is banned in group room1

when alice queries events for group room1

expect access denied
```

MSC:
```text
msc GroupScopedBanDoesNotRemoveMembership;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military
  - alice is member of group room1
  - alice is banned in group room1

  Alice -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)

## Global ban overrides group-scoped allow

DSL:
```text
scenario global ban overrides group-scoped allow

given alice has branch military
given feed room1 has branch military
given alice is member of group room1
given alice is banned

when alice queries events for group room1

expect access denied
```

MSC:
```text
msc GlobalBanOverridesGroupScopedAllow;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch military
  - feed room1 has branch military
  - alice is member of group room1
  - alice is banned

  Alice -> Server : EventQuery(group=room1);

  condition Forbidden(action);
endmsc;
```

Extensions used:
- Forbidden(action)
