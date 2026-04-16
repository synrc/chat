# MSC-SEARCH

## Search finds message in private feed

DSL:
```text
scenario search finds message in private feed

given
  private feed alice<->bob has messages
    1 from alice "draft v1"
    2 from bob "other"

session bob
connect
auth

query search peer alice text "draft"

expect result items
expect message from alice body "draft v1"
```

MSC:
```text
msc SearchFindsMessageInPrivateFeed;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft v1"
    2 from bob "other"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft");

  condition ResultNotEmpty;
  condition SearchShows(Message(from=Alice, body="draft v1"));
endmsc;
```

Extensions used:
- ResultNotEmpty
- SearchShows(x)

## Search in group respects membership

DSL:
```text
scenario search in group respects membership

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1

  group feed room1 has messages
    1 from alice "release draft"
    2 from bob "status"

session bob
connect
auth

query search group room1 text "draft"

expect result items
expect message from alice body "release draft"
```

MSC:
```text
msc SearchInGroupRespectsMembership;
  instance Bob;
  instance Server;

  Preconditions:
  - group room1 exists
  - alice is owner of group room1
  - bob is member of group room1
  - group feed room1 has messages:
    1 from alice "release draft"
    2 from bob "status"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=group:room1, text="draft");

  condition ResultNotEmpty;
  condition SearchShows(Message(from=Alice, body="release draft"));
endmsc;
```

Extensions used:
- ResultNotEmpty
- SearchShows(x)

## Search does not imply replay progress

DSL:
```text
scenario search does not imply replay progress

given
  private feed alice<->bob has messages
    1 from alice "draft v1"
    2 from alice "draft v2"

  bob read private:alice up to 1

session bob
connect
auth

query search peer alice text "draft"

expect result items

query events peer alice after cursor

expect events non-empty
```

MSC:
```text
msc SearchDoesNotImplyReplayProgress;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft v1"
    2 from alice "draft v2"
  - bob read private:alice up to 1

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft");

  condition ResultNotEmpty;

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- ResultNotEmpty

## Search respects group moderation

DSL:
```text
scenario search respects group moderation

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1
  bob is banned in group room1

  group feed room1 has messages
    1 from alice "draft policy"

session bob
connect
auth

query search group room1 text "draft"

expect error forbidden
```

MSC:
```text
msc SearchRespectsGroupModeration;
  instance Bob;
  instance Server;

  Preconditions:
  - group room1 exists
  - alice is owner of group room1
  - bob is member of group room1
  - bob is banned in group room1
  - group feed room1 has messages:
    1 from alice "draft policy"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=group:room1, text="draft");

  condition Error(forbidden);
endmsc;
```

Extensions used:
- Error(code)

## Global search returns only visible scope

DSL:
```text
scenario global search returns only visible scope

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1

  group room2 exists
  carol is owner of group room2

  private feed alice<->bob has messages
    1 from alice "draft private"

  group feed room1 has messages
    1 from alice "draft group one"

  group feed room2 has messages
    1 from carol "draft hidden"

session bob
connect
auth

query search text "draft"

expect result items
expect result items <= 2
expect message from alice body "draft private"
expect message from alice body "draft group one"
```

MSC:
```text
msc GlobalSearchReturnsOnlyVisibleScope;
  instance Bob;
  instance Server;

  Preconditions:
  - group room1 exists
  - alice is owner of group room1
  - bob is member of group room1
  - group room2 exists
  - carol is owner of group room2
  - private feed alice<->bob has messages:
    1 from alice "draft private"
  - group feed room1 has messages:
    1 from alice "draft group one"
  - group feed room2 has messages:
    1 from carol "draft hidden"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=all, text="draft");

  condition ResultNotEmpty;
  condition ResultCount <= 2;
  condition SearchShows(Message(from=Alice, body="draft private"));
  condition SearchShows(Message(from=Alice, body="draft group one"));
  condition SearchHides(Message(from=Carol, body="draft hidden"));
endmsc;
```

Extensions used:
- ResultCount relation
- ResultNotEmpty
- SearchHides(x)
- SearchShows(x)

## Search hides restricted messages

DSL:
```text
scenario search hides restricted messages

given alice has clearance confidential
given message m1 has classification confidential
given message m2 has classification secret

when alice queries inbox

expect message m1 visible
expect message m2 hidden

session alice
connect
auth

query search text "draft"

expect result items <= 1
```

MSC:
```text
msc SearchHidesRestrictedMessages;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has clearance confidential
  - message m1 has classification confidential
  - message m2 has classification secret

  Alice -> Server : InboxQuery();

  condition Visible(m1);
  condition Hidden(m2);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=all, text="draft");

  condition ResultCount <= 1;
endmsc;
```

Extensions used:
- Hidden
- ResultCount relation
- Visible

## Search does not leak restricted group content through global scope

DSL:
```text
scenario search does not leak restricted group content through global scope

given alice has branch civil
given bob has branch military
given feed room1 has branch civil
given feed room2 has branch military

when alice queries inbox

expect access allowed

session alice
connect
auth

query search text "draft"

expect result items <= 1
```

MSC:
```text
msc SearchDoesNotLeakRestrictedGroupContentThroughGlobalScope;
  instance Alice;
  instance Server;

  Preconditions:
  - alice has branch civil
  - bob has branch military
  - feed room1 has branch civil
  - feed room2 has branch military

  Alice -> Server : InboxQuery();

  condition Permitted(action);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=all, text="draft");

  condition ResultCount <= 1;
endmsc;
```

Extensions used:
- Permitted(action)
- ResultCount relation

## Search respects field-level visibility

DSL:
```text
scenario search respects field-level visibility

given alice has clearance confidential
given message m1 has classification secret
given message m1 field body visible at level confidential
given message m1 field attachment visible at level secret

when alice queries inbox

expect message m1 field body visible
expect message m1 field attachment hidden

session alice
connect
auth

query search text "draft"

expect result items <= 1
```

MSC:
```text
msc SearchRespectsFieldLevelVisibility;
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

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=all, text="draft");

  condition ResultCount <= 1;
endmsc;
```

Extensions used:
- FieldHidden(x, field)
- FieldVisible(x, field)
- ResultCount relation

## Search first page returns limited items

DSL:
```text
scenario search first page returns limited items

given
  private feed alice<->bob has messages
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

session bob
connect
auth

query search peer alice text "draft" limit 2

expect result items
expect result items <= 2
expect more
expect next
```

MSC:
```text
msc SearchFirstPageReturnsLimitedItems;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2);

  condition ResultNotEmpty;
  condition ResultCount <= 2;
  condition HasMore;
  condition HasNext;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ResultCount relation
- ResultNotEmpty

## Search continue returns next page

DSL:
```text
scenario search continue returns next page

given
  private feed alice<->bob has messages
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

session bob
connect
auth

query search peer alice text "draft" limit 2

expect result items
expect more
expect next

query search continue

expect result items
expect result items <= 1
expect not more
```

MSC:
```text
msc SearchContinueReturnsNextPage;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;

  Bob -> Server : SearchQuery(continue);

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition HasMore = false;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ResultCount relation
- ResultNotEmpty

## Search pagination does not imply replay progress

DSL:
```text
scenario search pagination does not imply replay progress

given
  private feed alice<->bob has messages
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

bob read private:alice up to 1

session bob
connect
auth

query search peer alice text "draft" limit 1

expect result items
expect more
expect next

query search continue

expect result items

query events peer alice after cursor

expect events non-empty
```

MSC:
```text
msc SearchPaginationDoesNotImplyReplayProgress;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"
  - bob read private:alice up to 1

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=1);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;

  Bob -> Server : SearchQuery(continue);

  condition ResultNotEmpty;

  Bob -> Server : EventQuery(peer=alice, after=cursor);

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ResultNotEmpty

## Global search pagination still respects visibility

DSL:
```text
scenario global search pagination still respects visibility

given
  private feed alice<->bob has messages
    1 id "m1" from bob "draft visible a"
    2 id "m2" from bob "draft visible b"
    3 id "m3" from bob "archive hidden"
  alice has clearance confidential
  message m1 has classification confidential
  message m2 has classification confidential
  message m3 has classification secret

when alice queries inbox

expect message m1 visible
expect message m2 visible
expect message m3 hidden

session alice
connect
auth

query search text "draft" limit 1

expect result items
expect result items <= 1
expect more
expect next

query search continue

expect result items
expect result items <= 1
expect not more
```

MSC:
```text
msc GlobalSearchPaginationStillRespectsVisibility;
  instance Alice;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "m1" from bob "draft visible a"
    2 id "m2" from bob "draft visible b"
    3 id "m3" from bob "archive hidden"
  - alice has clearance confidential
  - message m1 has classification confidential
  - message m2 has classification confidential
  - message m3 has classification secret

  Alice -> Server : InboxQuery();

  condition Visible(m1);
  condition Visible(m2);
  condition Hidden(m3);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=all, text="draft", limit=1);

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition HasMore;
  condition HasNext;

  Alice -> Server : SearchQuery(continue);

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition HasMore = false;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- Hidden
- ResultCount relation
- ResultNotEmpty
- Visible

## Search by field body like

DSL:
```text
scenario search by field body like

given
  private feed alice<->bob has messages
  1 from alice {
    body: "draft v1"
    tag: "release"
  }
  2 from alice {
    body: "status"
    tag: "note"
  }

session bob
connect
auth

query search peer alice field body like "draft"

expect result items
expect message from alice {
  body: "draft v1"
  tag: "release"
}
```

MSC:
```text
msc SearchByFieldBodyLike;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice {body="draft v1", tag="release"}
    2 from alice {body="status", tag="note"}

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, field=body, criteria=like, value="draft");

  condition ResultNotEmpty;
  condition SearchShows(Message(from=Alice, body="draft v1", tag="release"));
endmsc;
```

Extensions used:
- ResultNotEmpty
- SearchShows(x)

## Search by field exact match

DSL:
```text
scenario search by field exact match

given
  private feed alice<->bob has messages
  1 from alice {
    body: "draft v1"
    tag: "release"
  }
  2 from alice {
    body: "draft v2"
    tag: "note"
  }

session bob
connect
auth

query search peer alice field tag equal "release"

expect result items
expect result items <= 1
expect message from alice {
  body: "draft v1"
  tag: "release"
}
```

MSC:
```text
msc SearchByFieldExactMatch;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice {body="draft v1", tag="release"}
    2 from alice {body="draft v2", tag="note"}

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, field=tag, criteria=equal, value="release");

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition SearchShows(Message(from=Alice, body="draft v1", tag="release"));
endmsc;
```

Extensions used:
- ResultCount relation
- ResultNotEmpty
- SearchShows(x)

## Hidden field is not searchable

DSL:
```text
scenario hidden field is not searchable

given
  private feed alice<->bob has messages
    1 id "m1" from bob {
      body: "visible draft"
      attachment: "secret-plan.pdf"
    }

alice has clearance confidential
message m1 has classification secret
message m1 field body visible at level confidential
message m1 field attachment visible at level secret

when alice queries inbox

expect message m1 field body visible
expect message m1 field attachment hidden

session alice
connect
auth

query search peer bob field attachment like "secret"

expect result items = 0
```

MSC:
```text
msc HiddenFieldIsNotSearchable;
  instance Alice;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "m1" from bob {body="visible draft", attachment="secret-plan.pdf"}
  - alice has clearance confidential
  - message m1 has classification secret
  - message m1 field body visible at level confidential
  - message m1 field attachment visible at level secret

  Alice -> Server : InboxQuery();

  condition FieldVisible(m1, body);
  condition FieldHidden(m1, attachment);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=peer:bob, field=attachment, criteria=like, value="secret");

  condition ResultCount = 0;
endmsc;
```

Extensions used:
- FieldHidden(x, field)
- FieldVisible(x, field)
- ResultCount relation

## Peer field search respects visibility

DSL:
```text
scenario peer field search respects visibility

given
private feed alice<->bob has messages
  1 id "m1" from bob {
    body: "visible draft"
    tag: "release"
  }
  2 id "m2" from bob {
    body: "hidden draft"
    tag: "release"
  }

alice has clearance confidential
message m1 has classification confidential
message m2 has classification secret
message m1 field tag visible at level confidential
message m2 field tag visible at level secret

when alice queries inbox

expect message m1 visible
expect message m2 hidden

session alice
connect
auth

query search peer bob field tag equal "release"

expect result items
expect result items <= 1
expect message from bob {
  body: "visible draft"
  tag: "release"
}
```

MSC:
```text
msc PeerFieldSearchRespectsVisibility;
  instance Alice;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "m1" from bob {body="visible draft", tag="release"}
    2 id "m2" from bob {body="hidden draft", tag="release"}
  - alice has clearance confidential
  - message m1 has classification confidential
  - message m2 has classification secret
  - message m1 field tag visible at level confidential
  - message m2 field tag visible at level secret

  Alice -> Server : InboxQuery();

  condition Visible(m1);
  condition Hidden(m2);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=peer:bob, field=tag, criteria=equal, value="release");

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition SearchShows(Message(from=Bob, body="visible draft", tag="release"));
  condition SearchHides(Message(id=m2));
endmsc;
```

Extensions used:
- Hidden
- ResultCount relation
- ResultNotEmpty
- SearchHides(x)
- SearchShows(x)
- Visible

## Group field search respects moderation

DSL:
```text
scenario group field search respects moderation

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1
  bob is banned in group room1

group feed room1 has messages
1 from alice {
  body: "release draft"
  tag: "release"
}

session bob
connect
auth

query search group room1 field tag equal "release"

expect error forbidden
```

MSC:
```text
msc GroupFieldSearchRespectsModeration;
  instance Bob;
  instance Server;

  Preconditions:
  - group room1 exists
  - alice is owner of group room1
  - bob is member of group room1
  - bob is banned in group room1
  - group feed room1 has messages:
    1 from alice {body="release draft", tag="release"}

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=group:room1, field=tag, criteria=equal, value="release");

  condition Error(forbidden);
endmsc;
```

Extensions used:
- Error(code)

## Search projection returns requested fields only

DSL:
```text
scenario search projection returns requested fields only

given
  private feed alice<->bob has messages
  1 from alice {
    body: "draft v1"
    tag: "release"
    attachment: "plan.pdf"
  }
  2 from alice {
    body: "status"
    tag: "note"
    attachment: "note.txt"
  }

session bob
connect
auth

query search peer alice field body like "draft" return body tag

expect result items
expect message from alice {
  body: "draft v1"
  tag: "release"
}
```

MSC:
```text
msc SearchProjectionReturnsRequestedFieldsOnly;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice {body="draft v1", tag="release", attachment="plan.pdf"}
    2 from alice {body="status", tag="note", attachment="note.txt"}

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, field=body, criteria=like, value="draft", fields=[body, tag]);

  condition ResultNotEmpty;
  condition SearchShows(Message(from=Alice, body="draft v1", tag="release"));
  condition ProjectionPreserved;
endmsc;
```

Extensions used:
- ProjectionPreserved
- ResultNotEmpty
- SearchShows(x)

## Hidden field is not returned even if body matched

DSL:
```text
scenario hidden field is not returned even if body matched

given
private feed alice<->bob has messages
  1 id "m1" from bob {
    body: "visible draft"
    tag: "release"
    attachment: "secret-plan.pdf"
  }

alice has clearance confidential
message m1 has classification secret
message m1 field body visible at level confidential
message m1 field tag visible at level confidential
message m1 field attachment visible at level secret

when alice queries inbox

expect message m1 field body visible
expect message m1 field tag visible
expect message m1 field attachment hidden

session alice
connect
auth

query search peer bob field body like "draft" return body tag attachment

expect result items
expect message from bob {
  body: "visible draft"
  tag: "release"
}
```

MSC:
```text
msc HiddenFieldIsNotReturnedEvenIfBodyMatched;
  instance Alice;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "m1" from bob {body="visible draft", tag="release", attachment="secret-plan.pdf"}
  - alice has clearance confidential
  - message m1 has classification secret
  - message m1 field body visible at level confidential
  - message m1 field tag visible at level confidential
  - message m1 field attachment visible at level secret

  Alice -> Server : InboxQuery();

  condition FieldVisible(m1, body);
  condition FieldVisible(m1, tag);
  condition FieldHidden(m1, attachment);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=peer:bob, field=body, criteria=like, value="draft", fields=[body, tag, attachment]);

  condition ResultNotEmpty;
  condition SearchShows(Message(from=Bob, body="visible draft", tag="release"));
  condition ProjectionPreserved;
endmsc;
```

Extensions used:
- FieldHidden(x, field)
- FieldVisible(x, field)
- ProjectionPreserved
- ResultNotEmpty
- SearchShows(x)

## Projection does not bypass message visibility

DSL:
```text
scenario projection does not bypass message visibility

given
private feed alice<->bob has messages
1 id "m1" from bob {
  body: "visible draft"
  tag: "release"
}
2 id "m2" from bob {
  body: "hidden draft"
  tag: "release"
}

alice has clearance confidential
message m1 has classification confidential
message m2 has classification secret
message m1 field tag visible at level confidential
message m2 field tag visible at level secret

when alice queries inbox

expect message m1 visible
expect message m2 hidden

session alice
connect
auth

query search peer bob field tag equal "release" return body tag

expect result items
expect result items <= 1
expect message from bob {
  body: "visible draft"
  tag: "release"
}
```

MSC:
```text
msc ProjectionDoesNotBypassMessageVisibility;
  instance Alice;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 id "m1" from bob {body="visible draft", tag="release"}
    2 id "m2" from bob {body="hidden draft", tag="release"}
  - alice has clearance confidential
  - message m1 has classification confidential
  - message m2 has classification secret
  - message m1 field tag visible at level confidential
  - message m2 field tag visible at level secret

  Alice -> Server : InboxQuery();

  condition Visible(m1);
  condition Hidden(m2);

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : SearchQuery(scope=peer:bob, field=tag, criteria=equal, value="release", fields=[body, tag]);

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition SearchShows(Message(from=Bob, body="visible draft", tag="release"));
  condition SearchHides(Message(id=m2));
  condition ProjectionPreserved;
endmsc;
```

Extensions used:
- Hidden
- ProjectionPreserved
- ResultCount relation
- ResultNotEmpty
- SearchHides(x)
- SearchShows(x)
- Visible

## Projection is preserved across pagination

DSL:
```text
scenario projection is preserved across pagination

given
private feed alice<->bob has messages
  1 from alice {
    body: "draft a"
    tag: "release"
    attachment: "a.pdf"
  }
  2 from alice {
    body: "draft b"
    tag: "release"
    attachment: "b.pdf"
  }
  3 from alice {
    body: "draft c"
    tag: "release"
    attachment: "c.pdf"
  }

session bob
connect
auth

query search peer alice field tag equal "release" return body tag limit 2

expect result items
expect result items <= 2
expect more
expect next

query search continue

expect result items
expect result items <= 1
```

MSC:
```text
msc ProjectionIsPreservedAcrossPagination;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice {body="draft a", tag="release", attachment="a.pdf"}
    2 from alice {body="draft b", tag="release", attachment="b.pdf"}
    3 from alice {body="draft c", tag="release", attachment="c.pdf"}

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, field=tag, criteria=equal, value="release", fields=[body, tag], limit=2);

  condition ResultNotEmpty;
  condition ResultCount <= 2;
  condition HasMore;
  condition HasNext;
  condition ProjectionPreserved;

  Bob -> Server : SearchQuery(continue);

  condition ResultNotEmpty;
  condition ResultCount <= 1;
  condition ProjectionPreserved;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ProjectionPreserved
- ResultCount relation
- ResultNotEmpty

## Same query keeps stable order on unchanged result set

DSL:
```text
scenario same query keeps stable order on unchanged result set

given
  private feed alice<->bob has messages
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

session bob
connect
auth

query search peer alice text "draft" limit 2

expect result items
expect more
expect next

query search peer alice text "draft" limit 2

expect result items
expect more
expect next
```

MSC:
```text
msc SameQueryKeepsStableOrderOnUnchangedResultSet;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ResultNotEmpty

Notes:
- Stable ordering for repeated identical search queries is assumed but not directly expressed by an existing predicate.

## Continue does not duplicate items in unchanged result set

DSL:
```text
scenario search continue does not duplicate items in unchanged result set

given
  private feed alice<->bob has messages
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"
    4 from alice "draft d"

session bob
connect
auth

query search peer alice text "draft" limit 2

expect result items
expect more
expect next

query search continue

expect result items
expect result items <= 2
expect not more
```

MSC:
```text
msc ContinueDoesNotDuplicateItemsInUnchangedResultSet;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"
    4 from alice "draft d"

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;

  Bob -> Server : SearchQuery(continue);

  condition ResultNotEmpty;
  condition ResultCount <= 2;
  condition HasMore = false;
  condition NoDuplicates;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- NoDuplicates
- ResultCount relation
- ResultNotEmpty

## Search projection does not affect ordering

DSL:
```text
scenario search projection does not affect ordering

given
  private feed alice<->bob has messages
    1 from alice {
      body: "draft a"
      tag: "release"
      attachment: "a.pdf"
    }
    2 from alice {
      body: "draft b"
      tag: "release"
      attachment: "b.pdf"
    }
    3 from alice {
      body: "draft c"
      tag: "release"
      attachment: "c.pdf"
    }

session bob
connect
auth

query search peer alice field tag equal "release" limit 2

expect result items
expect more
expect next

query search peer alice field tag equal "release" return body tag limit 2

expect result items
expect more
expect next
```

MSC:
```text
msc SearchProjectionDoesNotAffectOrdering;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice {body="draft a", tag="release", attachment="a.pdf"}
    2 from alice {body="draft b", tag="release", attachment="b.pdf"}
    3 from alice {body="draft c", tag="release", attachment="c.pdf"}

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, field=tag, criteria=equal, value="release", limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;

  Bob -> Server : SearchQuery(scope=peer:alice, field=tag, criteria=equal, value="release", fields=[body, tag], limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;
  condition ProjectionPreserved;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ProjectionPreserved
- ResultNotEmpty

Notes:
- Unchanged ordering across different projections is assumed but not directly expressed by an existing predicate.

## Search pagination after mutation may change result window

DSL:
```text
scenario search pagination after mutation may change result window

given
  private feed alice<->bob has messages
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

session alice
connect
auth

session bob
connect
auth

session bob
query search peer alice text "draft" limit 2

expect result items
expect more
expect next

session alice
send message to bob "draft d"

session bob
query search continue

expect result items
```

MSC:
```text
msc SearchPaginationAfterMutationMayChangeResultWindow;
  instance Alice;
  instance Bob;
  instance Server;

  Preconditions:
  - private feed alice<->bob has messages:
    1 from alice "draft a"
    2 from alice "draft b"
    3 from alice "draft c"

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2);

  condition ResultNotEmpty;
  condition HasMore;
  condition HasNext;

  Alice -> Server : SendMessage("draft d");
  Server -> Bob : DeliverMessage("draft d");

  Bob -> Server : SearchQuery(continue);

  condition ResultNotEmpty;
endmsc;
```

Extensions used:
- HasMore
- HasNext
- ResultNotEmpty

Notes:
- Changed result window after underlying mutation is allowed; snapshot-pinned search view is not assumed.
