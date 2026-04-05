> See DSL-CORE.md for language definition

## READ-1. Basic delivery

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

## READ-2. Delivery + read

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

## READ-3. Read cursor

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
- `id` може бути допоміжним reference, але джерелом істини є `feed + seq`

---

## READ-4. Multi-session

```
scenario cross-session read sync

session bob1 as bob
connect
auth

session bob2 as bob
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
- `bob1` і `bob2` є різними session одного й того самого user `bob`
- `read` ініціюється конкретною session, але оновлює user-level read state
- read cursor синхронізується між усіма session користувача
- unread є user-scoped і не повинен відрізнятись між session
---
## READ-5. Read backward ignored

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
query cursor read feed private:alice up to 2

session bob
expect read cursor updated

session bob
query cursor read feed private:alice up to 1

session bob
expect read cursor unchanged
```

- update з меншим seq не повинен зменшувати read cursor
- read cursor є монотонним


## READ-6. Read after reconnect

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


## READ-7. Read wrong feed

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
query cursor read feed private:carol up to 1

session bob
expect error badRequest
```

- read update повинен бути узгоджений з feed
- update в невалідному feed не повинен змінювати state

## READ-8. Read before delivery
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
query cursor read feed private:alice up to 2

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

## READ-9. Multi-feed read isolation

```
scenario multi-feed read isolation

session alice
connect
auth

session bob
connect
auth

session carol
connect
auth

session alice
create group room1
add bob to group room1
add carol to group room1

session alice
send message to bob "p1"

session carol
send message to group:room1 "g1"

session bob
expect message from alice body "p1"
expect message from carol body "g1"

session bob
send read group room1 for last

session bob
expect read cursor updated in group:room1
expect read cursor unchanged in private:alice
```

- read cursor є feed-scoped
- update в одному feed не повинен впливати на інший feed
- private і group feed повинні бути ізольовані на рівні cursor state



## READ-ADV. Consistency

```
scenario read persists after reconnect

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

expect events non-empty

send read for last

disconnect
reconnect
auth resume

query events peer alice after cursor

expect empty replay
expect not more
```

```
scenario replay respects read cursor

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

query events peer alice after cursor

expect empty replay
expect not more
```

```
scenario read is shared across sessions

session alice
connect
auth

session bob1 as bob
connect
auth

session bob2 as bob
connect
auth

session alice
send message to bob "m1"

session bob1
query events peer alice after cursor
send read for last

session bob2
query events peer alice after cursor

expect empty replay
expect not more
```
---

## READ-UNREAD. Unread and view semantics

```
scenario unread does not change without read

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
```
- доставка або replay самі по собі не означають `read`
- unread не повинен зменшуватись без явного read update

```
scenario read clears unread boundary for current head

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

session bob
send read for last

session bob
query events peer alice after cursor

expect empty replay
expect not more
```

- після явного read unread boundary зсувається до current head
- replay після cursor не повинен повертати вже прочитаний tail

```
scenario new message after read becomes unread again

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
expect events

session bob
send read for last

session alice
send message to bob "m2"

session bob
query events peer alice after cursor

expect events non-empty
```

- нові повідомлення після read формують новий unread tail
- read фіксує boundary, але не блокує майбутні події

```
scenario reconnect does not change unread by itself

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
disconnect
wait 500ms
reconnect
auth resume

session bob
query events peer alice after cursor

expect events non-empty
```

- reconnect або resume не повинні змінювати read/unread state
- unread зберігається до явного read

```
scenario older history view does not change read cursor

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

session bob
send read for last

session bob
query inbox peer alice

expect messages

session bob
query events peer alice after cursor

expect empty replay
expect not more
```

- перегляд історії (inbox/history) не повинен змінювати read cursor
- view navigation не повинна "відмотувати" unread назад