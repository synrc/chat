> See DSL-CORE.md for language definition

# DSL-PRESENCE

Цей файл описує presence semantics як protocol-observable event layer:

- presence event є окремим від message replay
- presence event не переписує message history
- actor у presence event form може бути explicit або wildcard
- presence observation має лишатися узгодженою через federation і home/snapshot flow

На цьому етапі DSL фіксує лише мінімальну presence surface:

- `disconnect` як джерело `offline` event
- `expect event presence offline ...`

`online` / `typing` semantics можуть бути розширені пізніше,
коли runner отримає явну runtime model для них.

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
expect event presence offline
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

expect event presence offline alice
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

expect event presence offline alice
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
expect event presence offline alice
```

- home snapshot є recovery/view boundary для feed,
  але не замінює presence observation
- presence event після snapshot лишається окремим observable fact