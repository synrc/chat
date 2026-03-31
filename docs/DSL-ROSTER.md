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

```
scenario mutual relation

session alice
connect
auth

session bob
connect
auth

session alice
add bob to roster

session bob
add alice to roster

session alice
query roster
expect bob in roster

session bob
query roster
expect alice in roster
```

- mutual relation означає, що обидва користувачі додали один одного
- обидва бачать один одного у своїх roster
- TODO: визначити, чи mutual relation має особливу семантику (наприклад, presence, trust, encryption)
---

## Scenario R5. One-way relation

```
scenario one-way relation

session alice
connect
auth

session bob
connect
auth

session alice
add bob to roster

session alice
query roster
expect bob in roster

session bob
query roster
expect alice not in roster
```

- relation може бути однонаправленим
- bob не повинен бачити alice у своєму roster без власної дії
- TODO: визначити, чи one-way relation впливає на messaging / presence / privacy
---

## Scenario R6. Messaging after remove from roster

```
scenario messaging after remove from roster

session alice
connect
auth

session bob
connect
auth

session alice
add bob to roster
query roster
expect bob in roster

remove bob from roster

query roster
expect bob not in roster

session alice
send message to bob "hi after remove"

session bob
expect message from alice body "hi after remove"
```

- remove from roster не повинен автоматично блокувати direct p2p messaging
- roster relation і message delivery не повинні змішуватись без окремої policy
- цей сценарій підсилює модель, де roster є view, а не gate
- TODO: якщо серверна policy захоче робити roster/relation gating, це має бути явно зафіксовано окремо