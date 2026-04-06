> See DSL-CORE.md for language definition
# DSL-MODERATION

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