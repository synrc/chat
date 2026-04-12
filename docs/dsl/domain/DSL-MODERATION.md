> See DSL-CORE.md for language definition
# DSL-MODERATION

Сценарії для global і group-scoped moderation поверх protocol truth

## Semantics

Moderation у DSL трактується як policy layer поверх protocol state.

За замовчуванням:

- ban / unban не змінюють canonical history
- ban / unban не змінюють roster або subscription state
- ban впливає тільки на future actions (send / query), але не переписує минуле

- already accepted message не відкочується після ban
- new commands після ban оцінюються за новим policy state

Це відповідає принципу:

- Message / Event = truth
- Moderation = access policy

Примітка:

- конкретна поведінка (наприклад, доступ до історії)
  може бути змінена server policy (ABAC)
  і не є жорстко зафіксованою на рівні DSL

### Scope

Moderation у DSL має два scopes:

- global / subject-scoped
- group-scoped

Global forms:

- `ban <user>`
- `unban <user>`
- `query moderation`

Group-scoped forms:

- `ban <user> in group <name>`
- `unban <user> in group <name>`
- `query moderation group <name>`

Group-scoped moderation:

- не означає global ban
- не видаляє membership автоматично
- впливає лише на future actions у цьому group resource

## MOD-1. Ban user
```
scenario ban user

session alice
connect
auth

ban bob

expect bob is banned
```
---
## MOD-2. Banned user cannot send direct message
```
scenario banned user cannot send direct message

session alice
connect
auth

session bob
connect
auth

session alice
ban bob

session bob
send message to alice "hi"

expect error forbidden
```
---
## MOD-3. Unban restores direct messaging
```
scenario unban restores direct messaging

session alice
connect
auth

session bob
connect
auth

session alice
ban bob
unban bob

session bob
send message to alice "hi"

session alice
expect message from bob body "hi"
```
---
## MOD-4. Query moderation list
```
scenario query moderation list

session alice
connect
auth

ban bob
ban carol

query moderation

expect moderation
expect bob in moderation
expect carol in moderation
```
---
## MOD-5. Moderation does not imply roster removal
```
scenario moderation does not imply roster removal

session alice
connect
auth

add bob to roster
ban bob

query roster

expect bob in roster
expect bob is banned
```
---
## MOD-6. Moderation does not imply subscription removal
```
scenario moderation does not imply subscription removal

session alice
connect
auth

add bob to roster
ban bob

query subscriptions

expect subscriptions
expect bob in subscriptions
```
---
## MOD-7. Ban does not rewrite history
```
scenario ban does not rewrite history

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
- ban не впливає на вже прийняті повідомлення
- history не переписується
---
## MOD-8. Ban blocks future messages only
```
scenario ban blocks future messages only

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

session bob
send message to alice "m2"

expect error forbidden
```
- ban впливає тільки на нові дії
- past і future чітко розділені

---
## MOD-9. Ban user in group
```
scenario ban user in group

session alice
connect
auth

create group room1
add bob to group room1

ban bob in group room1

query moderation group room1

expect moderation
expect bob in moderation
expect bob is banned in group room1
```

- group-scoped moderation створюється окремо від global moderation
- moderation list для group resource має бути inspectable

---
## MOD-10. Group ban blocks future group access
```
scenario group ban blocks future group access

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
query events group room1 after cursor

expect error forbidden
```

- group-scoped ban блокує future access лише до цього group resource
- membership саме по собі вже недостатнє після group ban

---
## MOD-11. Group ban does not imply global ban
```
scenario group ban does not imply global ban

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
send message to alice "hi"

session alice
expect message from bob body "hi"
```
- group-scoped moderation не блокує не пов'язані private interactions
- scope ban має лишатися явним
---

## MOD-12. Unban in group restores group access
```
scenario unban in group restores group access

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1
unban bob in group room1

session bob
query events group room1 after cursor

expect not error forbidden
```

- group-scoped unban прибирає лише group-scoped restriction
- global moderation state цим не змінюється
---

## MOD-13. Group ban blocks inbox query
```
scenario group ban blocks inbox query

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
query inbox group room1

expect error forbidden
```

- group-scoped ban має блокувати не тільки replay/events,
  а й inbox/view доступ до цього group resource

---
## MOD-14. Group ban blocks read update
```
scenario group ban blocks read update

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1

session bob
query cursor read group room1 up to 1

expect error forbidden
```

- group-scoped moderation має блокувати і cursor/read operations
  для цього самого group resource

---
## MOD-15. Group ban after home snapshot blocks later replay
```
scenario group ban after home snapshot blocks later replay

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

- попередньо отриманий home snapshot не гарантує майбутній доступ,
  якщо policy state змінився
- access check має виконуватись на момент actual query,
  а не на момент bootstrap

---
## MOD-16. Group unban restores inbox access
```
scenario group unban restores inbox access

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session alice
ban bob in group room1
unban bob in group room1

session bob
query inbox group room1

expect not error forbidden
```

- unban у group має відновлювати group-scoped view access
- це не змінює global moderation state
