> See DSL-CORE.md for language definition

# DSL-INVARIANTS

Сценарні міжшарові invariants для read, replay, moderation і ABAC visibility

Цей файл описує cross-layer invariants між:

- protocol state
- read semantics
- replay
- moderation
- ABAC / access policy

---

## INV-1. Read cursor is not affected by global moderation
```
scenario read cursor is not affected by global moderation

given
  private feed alice<->bob has messages
    1 from alice "m1"
    2 from alice "m2"
  bob read private:alice up to 2

session bob
connect
auth

session alice
connect
auth

session alice
ban bob

session bob
query cursor read peer alice up to 2

expect read cursor unchanged
```

- moderation не переписує read state
- read cursor є protocol state, а не policy state

---

## INV-2. ABAC view filtering does not change message truth
```
scenario ABAC view filtering does not change message truth

given
  message m1 has classification topsecret
  alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

- message truth і visibility є різними шарами
- hidden не означає absent

---

## INV-3. Group-scoped moderation overrides replay access
```
scenario group-scoped moderation overrides replay access

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1
  bob is banned in group room1
  group feed room1 has messages
    1 from alice "m1"

session bob
connect
auth

session bob
query events group room1 after cursor

expect error forbidden
```

- replay не обходить moderation policy
- access check виконується на момент query

---

## INV-4. Snapshot does not bypass later group ban
```
scenario snapshot does not bypass later group ban

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session bob
bootstrap home

session alice
ban bob in group room1

session bob
query events group room1 after snapshot

expect error forbidden
```

- snapshot anchor не гарантує майбутній доступ
- policy застосовується під час фактичного replay query

---

## INV-5. Group moderation does not rewrite history
```
scenario group moderation does not rewrite history

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
send message to group:room1 "m1"
session bob
expect message from alice body "m1"

session alice
ban bob in group room1

session bob
expect message from alice body "m1"
```

- moderation обмежує future access
- already observed history не переписується
