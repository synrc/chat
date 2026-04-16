# MSC-ADVANCED

## Legacy mutation sugar = ref

DSL:
```text
scenario legacy mutation sugar

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session alice
edit message "m1" body "m1 edited"

session bob
expect message from alice body "m1 edited"
```

MSC:
```text
msc LegacyMutationSugar;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Alice -> Server : EditMessage(ref="m1", field=body, value="m1 edited");
  Server -> Bob : DeliverMessage({body="m1 edited"});

  condition Seen(Message(from=Alice, body="m1 edited"));
endmsc;
```

Extensions used:
- Seen(Message(...))

## Ref is local scenario reference

DSL:
```text
scenario ref mutation semantics

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob {
body: "doc"
subject: "Draft"
}

session alice
edit message ref "doc" field subject "Draft v2"

session bob
expect message from alice {
body: "doc"
subject: "Draft v2"
}
```

MSC:
```text
msc RefMutationSemantics;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage({body="doc", subject="Draft"});
  Server -> Bob : DeliverMessage({body="doc", subject="Draft"});

  Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2");
  Server -> Bob : DeliverMessage({body="doc", subject="Draft v2"});

  condition Seen(Message(from=Alice, body="doc", subject="Draft v2"));
endmsc;
```

Extensions used:
- Seen(Message(...))

## Captured id is separate from ref

DSL:
```text
scenario mutation by captured id

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1" capture id as m1id

session alice
edit message id m1id body "m1 edited"
```

MSC:
```text
msc MutationByCapturedId;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Alice -> Server : EditMessage(id=m1id, field=body, value="m1 edited");
endmsc;
```

Extensions used:
- none

## Given seeded id alias supports mutation

DSL:
```text
scenario mutation by seeded id

given
  private feed alice<->bob has messages
    1 id "msg-123" as m1id from alice "m1"

session alice
connect
auth

edit message id m1id body "m1 edited"

session bob
connect
auth

expect message from alice body "m1 edited"
```

MSC:
```text
msc MutationBySeededId;
  instance Alice;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "msg-123" as m1id from alice "m1"

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : EditMessage(id=m1id, field=body, value="m1 edited");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  condition Seen(Message(from=Alice, body="m1 edited"));
endmsc;
```

Extensions used:
- Seen(Message(...))

## Given seeded id alias supports delete

DSL:
```text
scenario delete by seeded id

given
  private feed alice<->bob has messages
    1 id "msg-123" as m1id from alice "m1"

session alice
connect
auth

delete message id m1id

session bob
connect
auth

expect message deleted
expect not message body "m1"
```

MSC:
```text
msc DeleteBySeededId;
  instance Alice;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "msg-123" as m1id from alice "m1"

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DeleteMessage(id=m1id);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  condition FinalState(Message(id=m1id), deleted);
  condition Seen(Message(body="m1")) = false;
endmsc;
```

Extensions used:
- FinalState(target, state)
- Seen(Message(...))

## Structured given payload supports seeded id alias

DSL:
```text
scenario structured seeded id alias

given
  private feed alice<->bob has messages
    1 id "msg-123" as m1id from alice {
      body: "doc"
      subject: "Draft"
      priority: high
    }

session alice
connect
auth

edit message id m1id field subject "Draft v2"

session bob
connect
auth

expect message from alice {
  body: "doc"
  subject: "Draft v2"
  priority: high
}
```

MSC:
```text
msc StructuredSeededIdAlias;
  instance Alice;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "msg-123" as m1id from alice {body="doc", subject="Draft", priority=high}

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : EditMessage(id=m1id, field=subject, value="Draft v2");

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  condition Seen(Message(from=Alice, body="doc", subject="Draft v2", priority=high));
endmsc;
```

Extensions used:
- Seen(Message(...))

## Edit does not create second message

DSL:
```text
scenario edit does not create second message

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
edit message "m1" body "m1 edited"

session bob
expect message from alice body "m1 edited"
expect not message body "m1"
```

MSC:
```text
msc EditDoesNotCreateSecondMessage;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Alice -> Server : EditMessage(ref="m1", field=body, value="m1 edited");
  Server -> Bob : DeliverMessage({body="m1 edited"});

  condition Seen(Message(from=Alice, body="m1 edited"));
  condition Seen(Message(body="m1")) = false;
endmsc;
```

Extensions used:
- Seen(Message(...))

## Replay returns final edited state

DSL:
```text
scenario replay returns final edited state

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
edit message "m1" body "m1 edited"

session bob
query events peer alice after 0

expect message from alice body "m1 edited"
expect not message body "m1"
```

MSC:
```text
msc ReplayReturnsFinalEditedState;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");
  Alice -> Server : EditMessage(ref="m1", field=body, value="m1 edited");

  Bob -> Server : EventQuery(peer=alice, after=0);
  loop replay_events;
    Server -> Bob : ReplayEvent(MessageEvent(message, from=Alice, body="m1 edited"));
  endloop;

  condition Seen(Message(from=Alice, body="m1 edited"));
  condition Seen(Message(body="m1")) = false;
endmsc;
```

Extensions used:
- Seen(Message(...))

## Replay keeps deleted state over old payload

DSL:
```text
scenario replay keeps deleted state over old payload

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob {
  body: "doc"
  subject: "Draft"
}
delete message ref "doc"

session bob
query events peer alice after 0

expect message deleted
expect not message from alice {
  body: "doc"
  subject: "Draft"
}
```

MSC:
```text
msc ReplayKeepsDeletedStateOverOldPayload;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage({body="doc", subject="Draft"});
  Server -> Bob : DeliverMessage({body="doc", subject="Draft"});
  Alice -> Server : DeleteMessage(ref="doc");

  Bob -> Server : EventQuery(peer=alice, after=0);
  loop replay_events;
    Server -> Bob : ReplayEvent(MessageEvent(deleted));
  endloop;

  condition FinalState(Message(ref="doc"), deleted);
  condition Seen(Message(from=Alice, body="doc", subject="Draft")) = false;
endmsc;
```

Extensions used:
- FinalState(target, state)
- Seen(Message(...))

## Exact read event observation

DSL:
```text
scenario exact read event observation

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

send read for last

session alice
query events peer bob after cursor

expect event message read bob up to 1
```

MSC:
```text
msc ExactReadEventObservation;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=last_observed);

  Alice -> Server : EventQuery(peer=bob, after=cursor);

  condition Seen(MessageEvent(read, actor=Bob, up_to=1));
endmsc;
```

Extensions used:
- ResultNotEmpty
- Seen(MessageEvent(...))

## Wildcard actor read event observation

DSL:
```text
scenario wildcard actor read event observation

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

send read for last

session alice
query events peer bob after cursor

expect event message read up to 1
```

MSC:
```text
msc WildcardActorReadEventObservation;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition ResultNotEmpty;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=last_observed);

  Alice -> Server : EventQuery(peer=bob, after=cursor);

  condition Seen(MessageEvent(read, up_to=1));
endmsc;
```

Extensions used:
- ResultNotEmpty
- Seen(MessageEvent(...))

## Exact delete event observation

DSL:
```text
scenario exact delete event observation

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1" capture id as m1id
delete message id m1id

session bob
query events peer alice after cursor

expect event message deleted alice id m1id
```

MSC:
```text
msc ExactDeleteEventObservation;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");
  Alice -> Server : DeleteMessage(id=m1id);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(MessageEvent(deleted, actor=Alice, id=m1id));
endmsc;
```

Extensions used:
- Seen(MessageEvent(...))

## Exact presence event observation

DSL:
```text
scenario exact presence event observation

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

expect event presence offline alice
```

MSC:
```text
msc ExactPresenceEventObservation;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  Alice -> Server : Disconnect();

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition Seen(PresenceEvent(offline, actor=Alice));
endmsc;
```

Extensions used:
- Seen(PresenceEvent(...))

## Delete overrides reordered edit

DSL:
```text
scenario delete overrides reordered edit

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

session alice
delete message "m1"

session alice
edit message "m1" body "m1 edited"

session bob
expect message deleted
expect not message body "m1 edited"
```

MSC:
```text
msc DeleteOverridesReorderedEdit;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  condition Seen(Message(from=Alice, body="m1"));

  Alice -> Server : DeleteMessage(ref="m1");
  Alice -> Server : EditMessage(ref="m1", field=body, value="m1 edited");

  condition FinalState(Message(ref="m1"), deleted);
  condition Seen(Message(body="m1 edited")) = false;
endmsc;
```

Extensions used:
- FinalState(target, state)
- Seen(Message(...))

## Late delete after edit

DSL:
```text
scenario late delete after edit

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

session alice
edit message "m1" body "m1 edited"

session alice
delete message "m1"

session bob
expect message deleted
expect not message body "m1 edited"
```

MSC:
```text
msc LateDeleteAfterEdit;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  condition Seen(Message(from=Alice, body="m1"));

  Alice -> Server : EditMessage(ref="m1", field=body, value="m1 edited");
  Alice -> Server : DeleteMessage(ref="m1");

  condition FinalState(Message(ref="m1"), deleted);
  condition Seen(Message(body="m1 edited")) = false;
endmsc;
```

Extensions used:
- FinalState(target, state)
- Seen(Message(...))

## Ban after accepted direct message

DSL:
```text
scenario ban after accepted direct message

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
msc BanAfterAcceptedDirectMessage;
  instance Alice;
  instance Bob;
  instance Server;

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
- Seen(Message(...))

## Remove member after accepted group message

DSL:
```text
scenario remove member after accepted group message

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
send message to group:room1 "m1"

session alice
remove bob from group room1

session alice
expect message from bob body "m1"
```

MSC:
```text
msc RemoveMemberAfterAcceptedGroupMessage;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);

  Bob -> Server : SendGroupMessage(room1, "m1");
  Server -> Alice : DeliverGroupMessage(room1, "m1");

  Alice -> Server : RemoveMember(room1, Bob);

  condition Seen(Message(from=Bob, body="m1"));
endmsc;
```

Extensions used:
- Seen(Message(...))

## Remove member blocks next group message

DSL:
```text
scenario remove member blocks next group message

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1
remove bob from group room1

session bob
send message to group:room1 "m2"

expect error forbidden
```

MSC:
```text
msc RemoveMemberBlocksNextGroupMessage;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : CreateGroup(room1);
  Alice -> Server : AddMember(room1, Bob);
  Alice -> Server : RemoveMember(room1, Bob);

  Bob -> Server : SendGroupMessage(room1, "m2");

  condition Error(forbidden);
endmsc;
```

Extensions used:
- Error(code)

## Home snapshot then group deleted

DSL:
```text
scenario home snapshot then group deleted

session alice
connect

create group room1

bootstrap home

expect shared snapshot

delete group room1

query inbox group room1

expect error notFound
```

MSC:
```text
msc HomeSnapshotThenGroupDeleted;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();

  Alice -> Server : CreateGroup(room1);

  Alice -> Server : HomeQuery(...);

  condition HasSnapshot;

  Alice -> Server : DeleteGroup(room1);

  Alice -> Server : InboxQuery(group=room1);

  condition Error(notFound);
endmsc;
```

Extensions used:
- Error(code)
- HasSnapshot

## Version negotiation

DSL:
```text
scenario version negotiation

session alice
connect

auth supportedVsn [v1, v2]

expect selectedVsn v2
```

MSC:
```text
msc VersionNegotiation;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(supportedVsn=[v1, v2]);

  condition FinalState(SessionVersion(actor=Alice), v2);
endmsc;
```

Extensions used:
- FinalState(target, state)

## Federation routing

DSL:
```text
scenario federation routing

session alice
connect brokerA
auth

send message to bob@brokerB "hi"

session bob
connect brokerB
auth

expect message from alice body "hi"
```

MSC:
```text
msc FederationRouting;
  instance Alice;
  instance BrokerA;
  instance BrokerB;
  instance Bob;

  Alice -> BrokerA : Connect();
  Alice -> BrokerA : Authenticate(...);

  Alice -> BrokerA : SendMessage(to=bob@brokerB, body="hi");
  BrokerA -> BrokerB : FederateMessage(to=bob@brokerB, body="hi");
  BrokerB -> Bob : DeliverMessage("hi");

  Bob -> BrokerB : Connect();
  Bob -> BrokerB : Authenticate(...);

  condition Seen(Message(from=Alice, body="hi"));
endmsc;
```

Extensions used:
- Seen(Message(...))

## Federated read event propagation

DSL:
```text
scenario federated read event propagation

session alice
connect brokerA
auth

session bob
connect brokerB
auth

session alice
send message to bob@brokerB "m1"

session bob
query events peer alice after cursor
expect events

send read for last

session alice
query events peer bob@brokerB after cursor

expect event message read bob up to 1
```

MSC:
```text
msc FederatedReadEventPropagation;
  instance Alice;
  instance BrokerA;
  instance BrokerB;
  instance Bob;

  Alice -> BrokerA : Connect();
  Alice -> BrokerA : Authenticate(...);

  Bob -> BrokerB : Connect();
  Bob -> BrokerB : Authenticate(...);

  Alice -> BrokerA : SendMessage(to=bob@brokerB, body="m1");
  BrokerA -> BrokerB : FederateMessage(to=bob@brokerB, body="m1");
  BrokerB -> Bob : DeliverMessage("m1");

  Bob -> BrokerB : EventQuery(peer=alice, after=cursor);
  condition ResultNotEmpty;

  Bob -> BrokerB : UpdateReadCursor(feed=private:alice, up_to=last_observed);
  BrokerB -> BrokerA : FederateRead(feed=private:alice, up_to=1, actor=Bob);

  Alice -> BrokerA : EventQuery(peer=bob@brokerB, after=cursor);

  condition Seen(MessageEvent(read, actor=Bob, up_to=1));
endmsc;
```

Extensions used:
- ResultNotEmpty
- Seen(MessageEvent(...))

## Federated edit keeps message identity

DSL:
```text
scenario federated edit keeps message identity

session alice
connect brokerA
auth

session bob
connect brokerB
auth

session alice
send message to bob@brokerB "m1" capture id as m1id

session alice
edit message id m1id body "m1 edited"

session bob
expect message from alice body "m1 edited"
expect not message body "m1"
```

MSC:
```text
msc FederatedEditKeepsMessageIdentity;
  instance Alice;
  instance BrokerA;
  instance BrokerB;
  instance Bob;

  Alice -> BrokerA : Connect();
  Alice -> BrokerA : Authenticate(...);

  Bob -> BrokerB : Connect();
  Bob -> BrokerB : Authenticate(...);

  Alice -> BrokerA : SendMessage(to=bob@brokerB, body="m1");
  BrokerA -> BrokerB : FederateMessage(to=bob@brokerB, body="m1");
  BrokerB -> Bob : DeliverMessage("m1");

  Alice -> BrokerA : EditMessage(id=m1id, field=body, value="m1 edited");
  BrokerA -> BrokerB : FederateEdit(id=m1id, field=body, value="m1 edited");

  condition Seen(Message(from=Alice, body="m1 edited"));
  condition Seen(Message(body="m1")) = false;
endmsc;
```

Extensions used:
- Seen(Message(...))

## Federated delete converges to final state

DSL:
```text
scenario federated delete converges to final state

session alice
connect brokerA
auth

session bob
connect brokerB
auth

session alice
send message to bob@brokerB "m1" capture id as m1id

session alice
delete message id m1id

session bob
expect message deleted
expect not message body "m1"
```

MSC:
```text
msc FederatedDeleteConvergesToFinalState;
  instance Alice;
  instance BrokerA;
  instance BrokerB;
  instance Bob;

  Alice -> BrokerA : Connect();
  Alice -> BrokerA : Authenticate(...);

  Bob -> BrokerB : Connect();
  Bob -> BrokerB : Authenticate(...);

  Alice -> BrokerA : SendMessage(to=bob@brokerB, body="m1");
  BrokerA -> BrokerB : FederateMessage(to=bob@brokerB, body="m1");
  BrokerB -> Bob : DeliverMessage("m1");

  Alice -> BrokerA : DeleteMessage(id=m1id);
  BrokerA -> BrokerB : FederateDelete(id=m1id);

  condition FinalState(Message(id=m1id), deleted);
  condition Seen(Message(body="m1")) = false;
endmsc;
```

Extensions used:
- FinalState(target, state)
- Seen(Message(...))

## Federated replay returns final edited state

DSL:
```text
scenario federated replay returns final edited state

session alice
connect brokerA
auth

session bob
connect brokerB
auth

session alice
send message to bob@brokerB "m1"
edit message "m1" body "m1 edited"

session bob
query events peer alice after 0

expect message from alice body "m1 edited"
expect not message body "m1"
```

MSC:
```text
msc FederatedReplayReturnsFinalEditedState;
  instance Alice;
  instance BrokerA;
  instance BrokerB;
  instance Bob;

  Alice -> BrokerA : Connect();
  Alice -> BrokerA : Authenticate(...);

  Bob -> BrokerB : Connect();
  Bob -> BrokerB : Authenticate(...);

  Alice -> BrokerA : SendMessage(to=bob@brokerB, body="m1");
  BrokerA -> BrokerB : FederateMessage(to=bob@brokerB, body="m1");
  BrokerB -> Bob : DeliverMessage("m1");

  Alice -> BrokerA : EditMessage(ref="m1", field=body, value="m1 edited");
  BrokerA -> BrokerB : FederateEdit(ref="m1", field=body, value="m1 edited");

  Bob -> BrokerB : EventQuery(peer=alice, after=0);
  loop replay_events;
    BrokerB -> Bob : ReplayEvent(MessageEvent(message, from=Alice, body="m1 edited"));
  endloop;

  condition Seen(Message(from=Alice, body="m1 edited"));
  condition Seen(Message(body="m1")) = false;
endmsc;
```

Extensions used:
- Seen(Message(...))

## Delete does not break read cursor

DSL:
```text
scenario delete does not break read cursor

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
send read for last

session alice
delete message "m1"

session bob
query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc DeleteDoesNotBreakReadCursor;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=last_observed);

  Alice -> Server : DeleteMessage(ref="m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- HasMore
- ReplayEmpty

## Edit after read does not re-deliver

DSL:
```text
scenario edit after read does not re-deliver

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
send read for last

session alice
edit message "m1" body "m1 edited"

session bob
query events peer alice after cursor

expect empty replay
expect not more
```

MSC:
```text
msc EditAfterReadDoesNotRedeliver;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("m1");
  Server -> Bob : DeliverMessage("m1");

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=last_observed);

  Alice -> Server : EditMessage(ref="m1", field=body, value="m1 edited");

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- HasMore
- ReplayEmpty
