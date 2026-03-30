# DSL Scenarios

## Purpose

На цьому етапі DSL використовується не як інструмент виконання, а як інструмент проєктування протоколу.

Мета:
- описати протокол через сценарії;
- перевірити, що всі ключові флоу можна виразити через послідовність дій і очікувань;
- виявити дірки в протоколі;
- зафіксувати вимоги до майбутньої серверної реалізації.

DSL — це природний опис поведінки:
- що робить клієнт;
- що має відбутися у відповідь.

---

## DSL Model

DSL має два рівні:

### Canonical (simple)

```
send message to alice "hi"
expect message from alice body "hi"
```

- мінімум
- дефолти
- intent

---

### Exact (precise)

```
query events after 100 limit 10
expect event message.received from alice
```

- точний контроль
- ближче до протоколу

---

## Duality

Simple:

```
expect message from alice "hi"
```

Exact:

```
expect event message.received from alice body "hi"
```

Simple = sugar  
Exact = truth

---

## Scenario 1. Basic delivery

```
scenario basic delivery

session alice
connect alice@example.com
auth password "secret"

session bob
connect bob@example.com
auth password "secret"

session alice
send message to bob "hi"

session bob
expect message from alice body "hi"
```

---

## Scenario 2. Delivery + read

```
scenario delivery + read

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
send read for last

session alice
expect event read
```
- `expect message ...` не означає `read`
- `read` виникає тільки після явної дії клієнта
- `delivered` і `read` мають перевірятись окремо

---

## Scenario 3. Multi-session

```
scenario multi-session read

session bob1
connect
auth

session bob2
connect
auth

session alice
connect
auth

session alice
send message to bob "hi"

session bob1
send read for last

session bob2
expect no read event
```

---

## Scenario 4. Replay

```
scenario replay

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "hi"

session bob
disconnect
wait 500ms
reconnect

expect message from alice body "hi"
```

---

## Scenario 5. Gap

```
scenario gap

session bob
connect
auth

query events after 0

expect error gapDetected
```

---

## Scenario 6. Gap recovery

```
scenario gap recovery

session bob
connect
auth

query events after 0
expect error gapDetected

query inbox feed bob
expect messages
```

---

## Scenario 7. Pagination

```
scenario inbox pagination

session bob
connect
auth

query inbox feed bob limit 10

expect result items <= 10
expect hasMore true

query inbox continue

expect result items
```

---

## Scenario 8. Event streaming

```
scenario event streaming

session bob
connect
auth

query events after 100 limit 10

expect events count <= 10
expect nextAfter
expect hasMore
```

---

## Scenario 9. Version

```
scenario version negotiation

session alice
connect

auth supportedVsn [v1, v2]

expect selectedVsn v2
```

---

## Scenario 10. Federation

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

## Summary

Покриття:
- delivery
- replay
- gap
- pagination
- session
- version
- federation

Якщо це все описується природно — протокол замкнутий.