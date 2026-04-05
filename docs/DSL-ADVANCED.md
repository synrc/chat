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

### ADV-MUT-4. Given seeded id alias supports mutation


```
scenario given seeded id mutation semantics

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

- `given` може явно задавати protocol-level message identity
- `as m1id` у `given` створює DSL alias для seeded protocol identity
- mutation через `id m1id` повинна працювати так само, як і для runtime `capture id as`

---

### ADV-MUT-5. Given seeded id alias supports delete

```
scenario given seeded id delete semantics

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
---

### ADV-MUT-6. Structured given payload supports seeded id alias

```
scenario structured given payload with seeded id alias

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
- explicit seeded id у given повинен працювати і для structured payload
- alias до seeded protocol identity повинен підтримувати field-level mutation
- structured given + seeded id має узгоджуватись із runtime mutation semantics
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

## ADV-EVENT. Exact event observation

```
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

- exact event form дозволяє перевіряти protocol-observable runtime fact
- `read` спостерігається як event, а не як message state
- canonical DSL використовує natural form `up to <seq>` замість protocol-level `readSeq`

---

```
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

- delete mutation має бути observable як message event
- exact event form дозволяє перевірити protocol identity через `id`
- це окремо від state-level assertion `expect message deleted`

---

```
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

- exact event form потрібна не лише для message family, а й для presence family
- це вирівнює DSL із protocol-level PresenceEvent semantics
- actor у canonical event form лишається опціональним, але тут заданий явно для точності

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
