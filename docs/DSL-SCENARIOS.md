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
query events bob after 100 limit 10
expect inbound message from alice body "hi"
```

- точний контроль
- ближче до протоколу

---

### Argument rules

DSL використовує два стилі: short і exact.

#### Short style

- команда може мати один основний позиційний аргумент
- тип цього аргументу визначається оператором (message/inbox/events/read)
- усі додаткові параметри задаються через ключові слова

Приклади:

- `send message to bob "hi"` — `bob` інтерпретується як target alias
- `query inbox bob` — `bob` інтерпретується як feed alias
- `query events bob after 100 limit 10` — `bob` інтерпретується як feed alias
- `send read for last` — short form для read cursor update
- `send read bob seq 123` = `query cursor read feed private:bob seq 123`


#### Exact style

- тип ресурсу задається явно
- alias розгортаються у повну форму
- exact форма використовується там, де потрібна точна protocol-level семантика

Приклади:

- `query inbox feed private:bob`
- `query events feed private:bob after 100 limit 10`
- `query cursor read feed private:alice seq 123`

#### Default resolution

контекст команди визначає, як інтерпретується identifier

- у message context `bob` означає user/target alias
- `query inbox bob` = `query inbox feed private:bob`
- `query events bob after 100 limit 10` = `query events feed private:bob after 100 limit 10`
- у inbox/events/read context `bob` означає feed alias
- `query inbox continue` продовжує останній `query inbox ...` у межах того самого feed

DSL допускає natural alias у short form, але exact інтерпретація завжди повинна зводитись до явного визначення feed або target.

DSL підтримує symbolic cursor значення:

- `last_seq`
- `nextAfter`
- `snapshot`

`snapshot` означає snapshot anchor, отриманий з попереднього inbox query

#### Expect semantics

- `expect events non-empty` означає, що результат містить хоча б одну подію
- `expect more` означає `expect hasMore true`
- `expect not more` означає `expect hasMore false`
- `expect snapshot` означає, що inbox result містить recovery anchor (`snapshotSeq`)
- `expect empty replay` означає, що replay result не містить подій (`events = 0`)
- `expect no duplicates` означає, що результат не містить елементів, уже покритих попереднім snapshot або попередньою сторінкою replay
- `expect no gaps` означає, що між попереднім recovery/snapshot boundary і поточним result немає втраченої ділянки історії

Argument rules застосовуються до обох рівнів DSL (canonical і exact).

## Duality

| Canonical                          | Exact                                             |
|----------------------------------|----------------------------------------------------|
| expect message from alice "hi"   | expect inbound message from alice body "hi"        |
| send read for last               | query cursor read feed private:alice seq 123       |
| expect more                      | expect hasMore true                                |
| query inbox continue             | query inbox feed private:alice continue            |
| query events bob after last_seq  | query events feed private:bob after last_seq       |
| expect events non-empty          | expect events count > 0                            |
| expect empty replay            | expect events = 0                               |
| expect no duplicates           | expect result has no duplicate items/events      |
| expect no gaps                 | expect result covers boundary without missing items/events |

Canonical = sugar  
Exact = protocol-observable semantics

### Read duality

Simple:

```
send read for last
```

Exact:

```
query cursor read feed private:alice seq 123
```

`send read ...` у canonical є sugar над `query cursor read ...` у exact формі.
У точній формі read повинен явно визначати:
- feed
- seq

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

session bob
send read for last

session alice
expect message marked as read
```

- цей сценарій перевіряє, що read не відбувається автоматично
- `expect message ...` не означає `read`
- `read` виникає тільки після явної cursor update команди клієнта
- `read` є cursor-based update, а не просто reference на message id
- `delivered` і `read` мають перевірятись окремо
- `expect message marked as read` означає оновлення read cursor, а не message-level flag
---

## Scenario 3. Read cursor

```
scenario read cursor

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
expect message from alice body "m1"
expect message from alice body "m2"

session bob
send read for last

session bob
expect read cursor updated
```

- цей сценарій перевіряє cursor semantics
- `send read for last` означає cursor update для read до seq останнього отриманого повідомлення
- read cursor є монотонним
- повторний read з меншим seq повинен ігноруватись
- `messageId` може бути допоміжним reference, але джерелом істини є `feed + seq`

---

## Scenario 4. Multi-session

```
scenario cross-session read sync

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
expect read cursor updated
```

- `read` ініціюється конкретною session, але оновлює user-level read state
- read cursor синхронізується між усіма session користувача
- unread є user-scoped і не повинен відрізнятись між session

## Scenario 4a. Read backward ignored

```
scenario read backward ignored

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
expect message from alice body "m1"
expect message from alice body "m2"

session bob
send read bob seq 2

session bob
expect read cursor updated

session bob
send read bob seq 1

session bob
expect read cursor unchanged
```

- update з меншим seq не повинен зменшувати read cursor
- read cursor є монотонним


## Scenario 4b. Read after reconnect

```
scenario read after reconnect

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
expect message from alice body "m1"
expect message from alice body "m2"

session bob
disconnect
wait 500ms
reconnect

session bob
send read for last

session bob
expect read cursor updated
```

- reconnect не повинен ламати cursor update semantics
- read після reconnect лишається валідним


## Scenario 4c. Read wrong feed

```
scenario read wrong feed

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

session bob
send read carol seq 1

session bob
expect error badRequest
```

- read update повинен бути узгоджений з feed
- update в невалідному feed не повинен змінювати state

## Scenario 4d. Read before delivery
```
scenario read before delivery

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
send read bob seq 2

session bob
expect message from alice body "m1"
expect message from alice body "m2"

session alice
expect message marked as read
```
- read не прив'язаний до факту доставки повідомлення у конкретну session
- read може обганяти delivery
- read визначає позицію у feed, а не факт отримання повідомлення
---

## Scenario 5. Replay

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

session bob
query events bob after last_seq

expect events non-empty
```

---

## Scenario 6. Gap

```
scenario gap

session bob
connect
auth

query events bob after 0

expect error gapDetected
```

---

## Scenario 7. Gap recovery

```
scenario gap recovery

session bob
connect
auth

query events bob after 0
expect error gapDetected

query inbox bob
expect messages
```

## Scenario 7a. Gap recovery with replay anchor

```
scenario gap recovery with replay anchor

session bob
connect
auth

query events bob after 0
expect error gapDetected

query inbox bob
expect messages
expect snapshot

query events bob after snapshot
```

- після gap recovery через inbox клієнт отримує snapshot anchor
- `snapshot` використовується для безшовного переходу назад у event replay
- replay після snapshot повинен починатися з `seq > snapshot`
---

## Scenario 8. Pagination

```
scenario inbox pagination

session bob
connect
auth

query inbox bob limit 10

expect result items <= 10
expect more

query inbox continue

expect result items
```

## Scenario 8a. Continue without initial query
```
scenario continue without initial query

session bob
connect
auth

query inbox continue

expect error badRequest
```
- continue без попереднього query не має контексту
- сервер не повинен вгадувати feed або cursor

## Scenario 8b. Continue after feed change
```
scenario continue after feed change

session bob
connect
auth

query inbox bob limit 10
expect result items

query inbox alice continue

expect error badRequest
```
- continue прив'язаний до конкретного feed
- зміна feed інвалідовує continuation context

## Scenario 8c. Empty page no more
```
scenario empty page no more

session bob
connect
auth

query inbox bob limit 10

expect result items = 0
expect not more
```
- пустий результат з hasMore=false означає кінець даних
---

## Scenario 9. Event streaming

```
scenario event streaming

session bob
connect
auth

query events bob after 100 limit 10

expect events count <= 10
expect nextAfter
expect more
```
## Scenario 9a. Event replay pagination
```
scenario event replay pagination

session bob
connect
auth

query events bob after 100 limit 2

expect events count <= 2
expect nextAfter

query events bob after nextAfter

expect events
```
## Scenario 9b. Replay no more
```
scenario replay no more

session bob
connect
auth

query events bob after last_seq

expect empty replay
expect not more
```
- коли немає нових подій, replay повертає пустий результат
---

## Scenario 10. Version

```
scenario version negotiation

session alice
connect

auth supportedVsn [v1, v2]

expect selectedVsn v2
```

---

## Scenario 11. Federation

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