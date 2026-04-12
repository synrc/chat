> See DSL-CORE.md for language definition

# DSL-PRESENCE

Сценарії для presence, typing, multi-session status і federation-aware observations

Цей файл описує presence semantics як protocol-observable event layer:

- presence event є окремим від message replay
- presence event не переписує message history
- actor у presence event form може бути explicit або wildcard
- presence observation має лишатися узгодженою через federation і home/snapshot flow

На цьому етапі DSL фіксує лише мінімальну presence surface:

- `disconnect` як джерело `offline` event
- canonical: `expect event offline ...`
- exact: `expect event presence offline ...`

На цьому етапі `offline` трактується як user-scoped aggregate presence fact.

Тобто:
- disconnect однієї session не обов'язково означає `offline`
- `offline` означає втрату останньої active session цього user

`online` already fixed as aggregate user-scoped companion event to `offline`.

---

## PRES-1. Wildcard offline presence observation
```
scenario wildcard offline presence observation

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

expect empty replay
expect event offline
```

- presence event може перевірятись без explicit actor
- presence observation є окремою від message replay items
- empty replay не означає відсутність presence event fact

---

## PRES-2. Offline presence does not rewrite delivered message
```
scenario offline presence does not rewrite delivered message

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

session bob
query events peer alice after cursor

session alice
disconnect

session bob
query events peer alice after cursor

expect event offline alice
expect message from alice body "m1"
```

- presence event не переписує вже доставлене message state
- message history і presence layer є різними semantic dimensions

---

## PRES-3. Federated offline presence observation
```
scenario federated offline presence observation

session alice
connect brokerA
auth

session bob
connect brokerB
auth

session bob
query events peer alice after cursor

session alice
disconnect

session bob
query events peer alice after cursor

expect event offline alice
```

- federation не повинна змінювати basic presence event semantics
- `offline` лишається тим самим protocol-observable fact across brokers

---

## PRES-4. Home snapshot does not replace presence observation
```
scenario home snapshot does not replace presence observation

session bob
connect
auth
add alice to roster

session alice
connect
auth

session bob
bootstrap home

expect feeds
expect shared snapshot

session alice
disconnect

session bob
query events peer alice after snapshot

expect empty replay
expect event offline alice
```

- home snapshot є recovery/view boundary для feed,
  але не замінює presence observation
- presence event після snapshot лишається окремим observable fact

---

## PRES-5. One of two sessions disconnects does not emit offline
```
scenario one of two sessions disconnects does not emit offline

session alice1 as alice
connect
auth

session alice2 as alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice1
disconnect

session bob
query events peer alice after cursor

expect empty replay
```

- `offline alice` не повинен виникати,
  якщо в alice лишається інша активна session
- `offline` за замовчуванням є user-scoped aggregate fact

---

## PRES-6. Last session disconnect emits offline
```
scenario last session disconnect emits offline

session alice1 as alice
connect
auth

session alice2 as alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice1
disconnect

session bob
query events peer alice after cursor
expect empty replay

session alice2
disconnect

session bob
query events peer alice after cursor

expect event offline alice
```

- `offline alice` має виникати лише після disconnect останньої active session
- це фіксує aggregate user presence semantics

---

## PRES-7. First session after offline emits online
```
scenario first session after offline emits online

session alice1 as alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice1
disconnect

session bob
query events peer alice after cursor
expect event offline alice

session alice2 as alice
connect
auth

session bob
query events peer alice after cursor

expect event online alice
```

- `online alice` має виникати,
  коли з'являється перша active session після fully-offline state
- `online` є природною парою до aggregate `offline`

---

## PRES-8. Typing event is observable
```
scenario typing event is observable

session alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor

session alice
send typing to bob

session bob
query events peer alice after cursor

expect event typing alice
```

- `typing` є protocol-observable presence event
- `typing` не є message item
- `typing` не означає delivery або replay progress

---

## PRES-9. Typing does not imply read
```
scenario typing does not imply read

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

session alice
send typing to bob

session bob
query events peer alice after cursor

expect event typing alice
expect not error badRequest
```

- `typing` не означає `read`
- `typing` не змінює read cursor
- `typing` не є substitute для message lifecycle event

---

## PRES-10. Typing does not survive replay or bootstrap as stable state
```
scenario typing does not survive replay or bootstrap as stable state

session alice
connect
auth

session bob
connect
auth

session alice
send typing to bob

session bob
query events peer alice after cursor
expect event typing alice

session bob
bootstrap home
expect feeds

session bob
query events peer alice after cursor
expect empty replay
```

- `typing` є transient presence event
- `typing` не повинен зберігатися як stable home state
- `typing` не повинен повторно з'являтись як replay artifact без нового runtime source
