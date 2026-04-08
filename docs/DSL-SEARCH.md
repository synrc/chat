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

Fielded canonical:

- `query search field body like "draft"`
- `query search peer alice field body like "draft"`
- `query search group room1 field body like "draft"`
- `query search field tag equal "release"`

Fielded exact:

- `query search scope all field body criteria like value "draft"`
- `query search scope peer alice field body criteria like value "draft"`
- `query search scope group room1 field body criteria like value "draft"`
- `query search scope all field tag criteria equal value "release"`

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

## SEARCH-3. Search does not imply replay progress
```
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

- search не є substitute для read
- search result не зсуває replay/read boundary
- після search звичайний replay/query semantics лишається незалежним

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
expect result items <= 2
expect message from alice body "draft private"
expect message from alice body "draft group one"
```

- global search є union visible scopes поточного user
- inaccessible scopes не повинні leak-ати через search
---

## SEARCH-7. Search hides restricted messages
```
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

- search не повинен повертати message,
  який hidden у поточному visibility / ABAC context
- match сам по собі не дає права бачити resource

---

## SEARCH-8. Search does not leak restricted group content through global scope
```
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

- global search не повинен leak-ати inaccessible scope
- visibility/policy rules для search повинні бути не слабші,
  ніж для інших view query

---

## SEARCH-9. Search respects field-level visibility
```
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

- search result не повинен обходити field-level visibility
- якщо message частково видимий,
  search view не повинен відкривати hidden fields неявно

---

## SEARCH-10. Search first page returns limited items
```
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

- search pagination використовує той самий continuation model,
  що й інші view query
- `limit` обмежує розмір поточної сторінки,
  але не змінює search semantics

---

## SEARCH-11. Search continue returns next page
```
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

- `continue` повертає наступну сторінку того самого search result
- continuation token є opaque
- pagination не повинна вимагати повторного формування query вручну

---

## SEARCH-12. Search pagination does not imply replay progress
```
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

- search pagination лишається view-only semantics
- `continue` у search не означає `read`
- `continue` у search не рухає replay boundary

---

## SEARCH-13. Global search pagination still respects visibility
```
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

- pagination не повинна послаблювати visibility / ABAC rules
- hidden content не повинно з'являтись на наступних сторінках лише через pagination

---

## SEARCH-14. Search by field body like
```
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

- fielded search може працювати по explicit payload field
- `body like` є природним field-specific варіантом text search

---

## SEARCH-15. Search by field exact match
```
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

- `equal` не повинен поводитись як substring match
- fielded search повинен дозволяти exact-match semantics

---

## SEARCH-16. Hidden field is not searchable
```
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

- hidden field не повинен бути searchable
- search index не повинен обходити field-level visibility

---

## SEARCH-17. Peer field search respects visibility
```
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

- peer field search повинен поважати message-level visibility
- однакове field value не дає права бачити hidden message

---

## SEARCH-18. Group field search respects moderation
```
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

- fielded search не обходить group-scoped moderation
- criteria/field search успадковує ті самі access rules, що й text search
---


## Notes

Search на цьому етапі не фіксує:

- ranking
- stemming
- fuzzy matching
- snippets/highlighting
- sort order beyond stable implementation-defined order
- richer result shaping for fielded search

Ці речі можуть бути додані пізніше,
коли буде погоджено базову protocol/query model для search.

На цьому етапі executable subset для search покриває:

- scope selection
- membership / moderation checks
- search як view без replay/read side effects
- visibility-aware filtering
- field-level visibility constraints

Fielded / criteria search semantics і richer result shaping
є наступним шаром DSL model.
