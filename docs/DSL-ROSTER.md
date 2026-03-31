# DSL Roster / Relation Scenarios

> See DSL-CORE.md for language definition

## Scenario R1. Add to roster

```
scenario add to roster

session alice
connect
auth

add bob to roster

query roster

expect bob in roster

```
- roster є view ресурcом для контактів / relation
- add to roster повинен робити bob видимим у roster alice
- TODO: exact relation model (Subscription vs Contact) ще має бути зафіксована в протоколі
---
## Scenario R2. Remove from roster

```
scenario remove from roster

session alice
connect
auth

add bob to roster
query roster
expect bob in roster

remove bob from roster

query roster

expect bob not in roster
```

- remove from roster прибирає контакт із roster view
- remove не обов'язково означає заборону direct messaging
- TODO: relation teardown semantics ще має бути уточнена в протоколі
---
## Scenario R3. Direct message without roster

```
scenario direct message without roster

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "hi"

session bob
expect message from alice body "hi"

session alice
query roster

expect bob not in roster
```
- direct p2p message не повинен автоматично означати roster relation
- roster і direct messaging не повинні змішуватись без явної policy
- цей сценарій фіксує модель, де roster є view, а не gate для p2p
---

## Scenario R4. Mutual relation

## Scenario R5. One-way relation