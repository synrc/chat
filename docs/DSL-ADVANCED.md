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
