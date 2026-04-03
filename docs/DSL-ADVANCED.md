> See DSL-CORE.md for language definition
## Conflict semantics

- authorization / policy / membership перевіряються за поточним server state
  на момент обробки конкретної command

- already accepted command не повинна відкочуватись ретроактивно
  через пізніший `ban`, `remove member` або `delete group`

- new command після зміни policy/resource state
  повинна оцінюватись уже за новим state

- snapshot / replay boundary не заморожує:
    - authorization
    - membership
    - existence resource

- snapshot дає recovery boundary,
  але не гарантує, що resource або access policy не зміниться після нього

## Message identity and mutation semantics

DSL розрізняє:
- `ref` — локальний сценарний reference
- `id` — protocol-level message identity

Mutation (`edit` / `delete`) застосовується до існуючого повідомлення,
а не створює новий message.

У protocol-observable моделі це відповідає event-level семантиці:
- mutation відображається як події (events),
  а не як окремі message об’єкти.

### ADV-MUT-1. Legacy mutation sugar = ref

```
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

- `edit message "m1"` інтерпретується як `edit message ref "m1"`
- legacy форма не означає protocol identity

---

### ADV-MUT-2. Ref is local scenario reference

```
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

- `ref` є DSL-level reference
- він може збігатися з `body` або іншим marker
- це не є protocol identity

---

### ADV-MUT-3. Captured id is separate from ref
```
scenario captured id mutation semantics

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

- `id` є protocol-level identity
- `id` не дорівнює `ref`
- exact mutation form буде визначена окремо
- цей сценарій фіксує semantic distinction між `ref` і captured protocol identity
- runner підтримує цей canonical flow через `capture id as`
---
## ADV-STATE. Event vs state alignment

```
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

- `edit` змінює current visible state існуючого повідомлення
- `edit` не повинен створювати другий visible message

---

```
scenario replay returns final edited state only

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

- replay повинен віддавати current final state, а не попередню visible версію повідомлення
- event history не повинен ламати state-level semantics для клієнта

---

```
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

- deleted state має мати пріоритет над old payload у replay/current state
- state assertion важливіша за наявність historical mutation events

---

## ADV-1. Delete overrides reordered edit

```
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

- delete має пріоритет над edit/update
- навіть якщо edit приходить після delete, повідомлення не повинно відновлюватись
- reorder подій не повинен ламати final state
- TODO: у майбутньому можна уточнити exact форму через явні Event.id / timestamp
---
## ADV-2. Late delete after edit

```
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

- delete має пріоритет над попереднім edit
- навіть якщо edit був застосований раніше, delete визначає final state
- final state повідомлення не повинен залежати від проміжного UI state
- TODO: у майбутньому можна уточнити exact форму через явні Event.id / timestamp
---

## ADV-3. Ban after accepted direct message
```
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
---
## ADV-4. Ban blocks next direct message
```
scenario ban blocks next direct message

session alice
connect
auth

session bob
connect
auth

session alice
ban bob

session bob
send message to alice "m2"

expect error forbidden
```
---
## ADV-5. Remove member after accepted group message
```
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
---
## ADV-6. Remove member blocks next group message
```
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
---
## ADV-7. Home snapshot then group deleted
```
scenario home snapshot then group deleted

session alice
connect
auth

create group room1

bootstrap home

expect shared snapshot

delete group room1

query inbox group room1

expect error notFound
```
---
## ADV-8. Version

```
scenario version negotiation

session alice
connect

auth supportedVsn [v1, v2]

expect selectedVsn v2
```

---

## ADV-9. Federation

```
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

---


## ADV-ORDERING. Causal consistency

```
scenario read is monotonic

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"

session bob
query events peer alice after cursor
expect events
send read for last

query cursor read feed private:alice seq 2
expect read cursor unchanged

query cursor read feed private:alice seq 1
expect read cursor unchanged
```

```
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

```
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
