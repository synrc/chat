> See DSL-CORE.md for language definition
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
query events bob after cursor

expect events non-empty
```

## Scenario 5a. Preview after reconnect

```
scenario preview after reconnect

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"
send message to bob "m3"

session bob
disconnect
wait 500ms
reconnect

session bob
query events bob after cursor limit 1

expect events count <= 1
expect more

send read for last
```
- після reconnect клієнт може запросити лише tail update для preview mode
- preview mode не означає full history recovery
- preview mode сам по собі не означає, що чат відкрито
- preview mode сам по собі не повинен імпліцитно вести до `read`
- навіть якщо клієнт викликає read після preview,
  це не означає, що весь feed прочитано

## Scenario 5b. Replay with concurrent read and new message

```
scenario replay read race

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"
send message to bob "m2"
send message to bob "m3"

session bob
disconnect
wait 500ms
reconnect

session bob
query events bob after cursor limit 2
expect events

session alice
send message to bob "m4"

session bob
send read for last

session bob
query events bob after next

expect events
expect no duplicates
```

- під час replay приходить нове повідомлення
- read виконується на partial replay
- replay продовжується після read
- система не повинна:
    - дублювати події
    - ламати cursor semantics
- нові події з seq > next можуть з'являтись у наступній replay page

## Scenario 5c. Duplicate event delivery

```
scenario duplicate event delivery

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
expect message from alice body "m1"

session bob
expect no duplicate side effects
```
- протокол допускає повторну доставку event/message
- повторна доставка того самого event не повинна створювати новий побічний ефект
- клієнт повинен бути ідемпотентним при обробці дубліката
- TODO: у майбутньому можна уточнити це через exact форму з явним Event.id
---

## Scenario 6. Gap

```
scenario gap

session bob
connect
auth

query events bob after 0

expect error gap
```

---

## Scenario 7. Gap recovery

```
scenario gap recovery

session bob
connect
auth

query events bob after 0
expect error gap

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
expect error gap

query inbox bob
expect messages
expect snapshot

query events bob after snapshot
```

- після gap recovery через inbox клієнт отримує snapshot anchor
- `snapshot` використовується для безшовного переходу назад у event replay
- replay після snapshot повинен починатися з `seq > snapshot`

## Scenario 7b. Gap recovery with concurrent message

```
scenario gap recovery with concurrent message

session bob
connect
auth

query events bob after 0
expect error gap

session alice
connect
auth

session alice
send message to bob "m3"

session bob
query inbox bob
expect messages
expect snapshot

session bob
query events bob after snapshot
expect no duplicates
expect no gaps
```
- повідомлення може з'явитись між `gap` і `query inbox`
- `snapshot` визначає recovery boundary між inbox і replay
- replay після `snapshot` не повинен дублювати вже покриті дані
- і не повинен залишати розрив між snapshot та replay

## Scenario 7c. Paged snapshot recovery
```
scenario paged snapshot recovery

session bob
connect
auth

query events bob after 0
expect error gap

query inbox bob limit 10
expect messages
expect snapshot
expect more

query inbox continue
expect messages

query events bob after snapshot
expect no duplicates
expect no gaps
```
- snapshot recovery може повертатися у кілька сторінок
- `snapshot` має лишатися спільним recovery boundary для всього paged snapshot
- replay після `snapshot` не повинен дублювати вже покриті дані
- і не повинен створювати розрив між snapshot та replay

## Scenario 7d. Multi-feed snapshot isolation

```
scenario multi-feed snapshot isolation

session bob
connect
auth

-- TODO: protocol currently has no explicit group creation flow
-- assume group:room1 already exists and bob is a member

query events private:alice after 0
expect error gap

query events group:room1 after 0
expect error gap

query inbox private:alice
expect messages
expect snapshot

query inbox group:room1
expect messages
expect snapshot

query events private:alice after snapshot
expect no duplicates
expect no gaps

query events group:room1 after snapshot
expect no duplicates
expect no gaps
```

- recovery boundary є feed-scoped
- snapshot для одного feed не повинен використовуватись як boundary для іншого
- inbox/replay consistency повинна зберігатись незалежно в кожному feed
- TODO: груповий feed тут використовується як already-existing feed, бо explicit group lifecycle ще не визначений
---

