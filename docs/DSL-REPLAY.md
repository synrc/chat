> See DSL-CORE.md for language definition
## REPLAY-1. Replay

```
scenario replay

given
  private feed alice<->bob has messages
    1 from alice "hi"

session bob
connect
auth
disconnect
wait 500ms
reconnect

session bob
query events peer alice after cursor

expect events non-empty
```

## REPLAY-2. Preview after reconnect

```
scenario preview after reconnect

given
  private feed alice<->bob has messages
    1 from alice "m1"
    2 from alice "m2"
    3 from alice "m3"

session bob
connect
auth
disconnect
wait 500ms
reconnect

session bob
query events peer alice after cursor limit 1

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
---
## REPLAY-3. Home bootstrap after reconnect

```
scenario home bootstrap after reconnect

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
disconnect
wait 500ms
reconnect

bootstrap home limit 20 preview 1

expect roster
expect feeds
expect previews
expect shared snapshot
```

- після reconnect клієнт може отримати стартовий стан через один home/bootstrap query
- home query є snapshot/view ресурсом
- home query не означає `read`
---
## REPLAY-4. Home bootstrap then replay
```
scenario home bootstrap then replay

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
disconnect
wait 500ms
reconnect

bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

query events peer alice after snapshot

expect no duplicates
expect no gaps
```

- home query повертає snapshot anchor для подальшого replay
- replay після `snapshot` валідний тільки для feed, вже покритих цим home result
- replay після `snapshot` не повинен дублювати preview, уже покритий home result
- replay після `snapshot` не повинен створювати розрив між bootstrap result і event stream
---
## REPLAY-5. Home bootstrap with concurrent message
```
scenario home bootstrap with concurrent message

session alice
connect
auth

session bob
connect
auth
add alice to roster

session alice
send message to bob "m1"
send message to bob "m2"

session bob
disconnect
wait 500ms
reconnect

bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

session alice
send message to bob "m3"

session bob
query events peer alice after snapshot

expect no duplicates
expect no gaps
expect events
```

- повідомлення може з'явитися після home snapshot
- такі події повинні добиратися через replay після `snapshot`
- replay після `snapshot` валідний тільки для feed, вже покритих цим home result
- home bootstrap і replay разом повинні давати безшовний recovery boundary
---

## REPLAY-6. Home bootstrap multi-feed replay

```
scenario home bootstrap multi-feed replay

session bob
connect
auth
add alice to roster

session alice
connect
auth
create group room1
add bob to group room1
send message to bob "p1"
send message to group:room1 "g1"

session bob
bootstrap home limit 20 preview 1

expect feeds
expect previews
expect shared snapshot

query events feed private:alice after snapshot

expect no duplicates
expect no gaps

query events group room1 after snapshot

expect no duplicates
expect no gaps
```

- home snapshot може використовуватись для replay у кількох feed
- replay boundary визначається для кожного feed окремо у межах того самого home bootstrap context
- snapshot не повинен створювати конфлікт між feed-scoped replay
- кожен feed повинен мати узгоджений перехід від preview до replay
- snapshot не означає, що всі feed мають однаковий seq boundary
---
## REPLAY-7. Replay with concurrent read and new message

```
scenario replay read race

given
  private feed alice<->bob has messages
    1 from alice "m1"
    2 from alice "m2"
    3 from alice "m3"

session alice
connect
auth

session bob
connect
auth
disconnect
wait 500ms
reconnect

session bob
query events peer alice after cursor limit 2
expect events

session alice
send message to bob "m4"

session bob
send read for last

session bob
query events peer alice after next

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

## REPLAY-8. Duplicate event delivery

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

## REPLAY-9. Gap

```
scenario gap

session bob
connect
auth

query events peer alice after 0

expect error gap
```

---

## REPLAY-10. Gap recovery

```
scenario gap recovery

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth
send message to bob "m1"

session bob
query inbox peer alice
expect messages
```

## REPLAY-11. Gap recovery with replay anchor

```
scenario gap recovery with replay anchor

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth
send message to bob "m1"

session bob
query inbox peer alice
expect messages
expect snapshot

query events peer alice after snapshot
```

- після gap recovery через inbox клієнт отримує snapshot anchor
- `snapshot` використовується для безшовного переходу назад у event replay
- replay після snapshot повинен починатися з `seq > snapshot`

## REPLAY-12. Gap recovery with concurrent message

```
scenario gap recovery with concurrent message

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth

session alice
send message to bob "m3"

session bob
query inbox peer alice
expect messages
expect snapshot

session bob
query events peer alice after snapshot
expect no duplicates
expect no gaps
```
- повідомлення може з'явитись між `gap` і `query inbox`
- `snapshot` визначає recovery boundary між inbox і replay
- replay після `snapshot` не повинен дублювати вже покриті дані
- і не повинен залишати розрив між snapshot та replay

## REPLAY-13. Paged snapshot recovery
```
scenario paged snapshot recovery

session bob
connect
auth

query events peer alice after 0
expect error gap

session alice
connect
auth
send message to bob "m1"
send message to bob "m2"
send message to bob "m3"
send message to bob "m4"
send message to bob "m5"
send message to bob "m6"
send message to bob "m7"
send message to bob "m8"
send message to bob "m9"
send message to bob "m10"
send message to bob "m11"

session bob
query inbox peer alice limit 10
expect messages
expect snapshot
expect more

query inbox continue
expect messages

query events peer alice after snapshot
expect no duplicates
expect no gaps
```
- snapshot recovery може повертатися у кілька сторінок
- `snapshot` має лишатися спільним recovery boundary для всього paged snapshot
- replay після `snapshot` не повинен дублювати вже покриті дані
- і не повинен створювати розрив між snapshot та replay

## REPLAY-14. Multi-feed snapshot isolation

```
scenario multi-feed snapshot isolation

session bob
connect
auth

session alice
connect
auth
create group room1
add bob to group room1
send message to bob "p1"
send message to group:room1 "g1"

session bob
query events feed private:alice after 0
expect error gap

query events group room1 after 0
expect error gap

query inbox feed private:alice
expect messages
expect snapshot

query inbox group room1
expect messages
expect snapshot

query events feed private:alice after snapshot
expect no duplicates
expect no gaps

query events group room1 after snapshot
expect no duplicates
expect no gaps
```

- recovery boundary є feed-scoped
- snapshot для одного feed не повинен використовуватись як boundary для іншого
- inbox/replay consistency повинна зберігатись незалежно в кожному feed
---

