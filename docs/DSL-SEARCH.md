> See DSL-CORE.md for language definition

# DSL-SEARCH

Цей файл описує search semantics як query/view extension поверх protocol model.

Search у DSL:

- не змінює Message/Event semantics
- не означає `read`
- не рухає replay cursor
- не замінює inbox/home/replay
- поважає visibility / ABAC / moderation / membership

На цьому етапі search трактується як projection/query layer,
а не як окремий feed або event stream.

---

## Search surface (minimal)

Canonical:

- `query search text "draft"`
- `query search peer alice text "draft"`
- `query search group room1 text "draft"`

Exact:

- `query search scope all text "draft"`
- `query search scope peer alice text "draft"`
- `query search scope group room1 text "draft"`

Search result:

- містить `result items`
- може містити message items
- не змінює message state
- не створює read/update side effects

---

## SEARCH-1. Search finds message in private feed
```
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

- search у private peer scope може знаходити message за text match
- search result є view над існуючим message state

---

## SEARCH-2. Search in group respects membership
```
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

- group search валідний лише в межах доступного group scope
- search не обходить group membership semantics

---

## SEARCH-3. Search does not change read cursor
```
scenario search does not change read cursor

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
expect read cursor unchanged in private:alice
```

- search не є substitute для read
- search result не зсуває read boundary

---

## SEARCH-4. Search respects visibility policy
```
scenario search respects visibility policy

given
  alice has clearance secret
  message m1 has classification topsecret
  message m1 field body visible at level topsecret

when alice queries inbox

expect access denied
```

- search semantics повинна поважати той самий visibility/filtering model,
  що і inbox/query view
- hidden content не повинен ставати search-visible лише через match

---

## SEARCH-5. Search respects group moderation
```
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

- search не обходить group-scoped moderation
- banned user не повинен отримувати search access до restricted group scope

---

## SEARCH-6. Global search returns only visible scope
```
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
expect message from alice body "draft private"
expect message from alice body "draft group one"
```

- global search є union visible scopes поточного user
- inaccessible scopes не повинні leak-ати через search

---

## SEARCH-7. Search result does not imply replay progress
```
scenario search result does not imply replay progress

given
private feed alice<->bob has messages
1 from alice "draft v1"
2 from alice "draft v2"

session bob
connect
auth

query search peer alice text "draft"

expect result items

query events peer alice after cursor

expect events non-empty
```

- search не означає replay progress
- після search звичайний replay/query semantics лишається незалежним

---

## Notes

Search на цьому етапі не фіксує:

- ranking
- stemming
- fuzzy matching
- snippets/highlighting
- pagination form для search result
- sort order beyond stable implementation-defined order

Ці речі можуть бути додані пізніше,
коли буде погоджено базову protocol/query model для search.