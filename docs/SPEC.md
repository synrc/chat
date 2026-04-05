# CHAT v2 Specification

## Overview

CHAT v2 — це messaging/pub-sub протокол з чітким розділенням між transport-пакетами, runtime-подіями, state/view моделлю та auth/session management. Протокол побудований так, щоб одна семантика не мала кількох паралельних wire-шляхів. 

Основні transport-level сутності:
- Message — тільки контент повідомлення
- Event — всі runtime події
- Query — єдиний request/response механізм
- Authority — auth, session і trust/bootstrap

## Design Principles

1. Одна семантика — один wire-шлях.
2. Message не містить lifecycle/runtime semantics.
3. Event є єдиним каналом runtime-подій.
4. Query є єдиним control/state request-response шаром.
5. Domain state і view не є top-level packet types. 

## Core Transport Model

### Message

Message описує тільки payload повідомлення і метадані, необхідні для доставки в межах feed.

Payload може бути структурованим і представляти document-like дані.

Message не обмежується plain text body і допускає семантику:
- document
- field
- value

Це необхідно для підтримки сценаріїв, де повідомлення використовується як носій структурованих даних (наприклад, ERP/1 документи або ABAC policy evaluation).

`body` є лише одним із можливих полів payload і не визначає всю модель повідомлення.

Message є ідемпотентним через глобально унікальний `Message.id`.  
Message.id є єдиним protocol-level identifier повідомлення.

- використовується для mutation (edit/delete)
- не залежить від payload
- не є пов'язаним із локальними reference (наприклад DSL ref)

Це узгоджується з DSL моделлю:
- `id` — protocol identity
- `ref` — локальний сценарний reference

Порядок повідомлень гарантується тільки в межах feed. 

### Event

Event є єдиним каналом runtime-подій:
- receipts
- presence
- edits / deletes / updates
- інші runtime state changes

Події мають `seq`, який:
- монотонно зростає
- визначений тільки в межах feed

Event delivery model:
- at-least-once
- можливі дублікати
- можливий reorder
- causal ordering не гарантується. 

### Event as runtime truth

Event є єдиним джерелом runtime truth.

Message state не є окремим persisted truth,
а виводиться як:

message_state = fold(events)

Це означає:

- edit/delete не створюють новий message
- вони змінюють state існуючого message
- replay повинен конвергувати до того самого фінального стану

Ця модель узгоджується з DSL сценаріями:
- delete overrides edit
- replay returns final state
- event ordering може бути некаузальним, але state має бути узгодженим

### Query

Query є єдиним механізмом для:
- state retrieval
- commands
- recovery
- paging
- error signaling

Типи Query:
- get
- set
- result
- error. 

### Authority

Authority відповідає за:
- authenticate
- renew
- revoke
- enroll
- trust/bootstrap semantics

Authority може виступати як:
- auth/session authority
- registration authority
- certification authority

Протокол не виконує parsing або validation PKIX/CMS payload на своєму рівні; certificate-related дані передаються як opaque binary. 

## Session Model

Протокол розділяє:
- Identity
- Device
- Session

Session:
- не є transport connection
- не є користувачем
- є runtime-інстансом клієнта
- переживає reconnect

Кожна session має власні:
- `last_seq`

Тут `last_seq` означає останню збережену session-local replay position
у термінах feed-scoped `seq`.

`read cursor` є user-scoped (per feed), а не session-scoped:
- всі session одного користувача спостерігають один і той самий read state
- read може бути ініційований будь-якою session
- результат синхронізується між усіма session цього користувача

### Session vs Read

Session і read cursor мають різну область:

- session:
    - має власний last_seq
    - відображає replay position конкретного клієнта

- read cursor:
    - є user-scoped
    - спільний між всіма session
    - відображає логічний read state користувача

Ці дві величини не повинні змішуватись.

Session lifecycle:
- створюється через `Authority.authenticate`
- може бути відновлена після reconnect
- може бути `active`, `expired`, `revoked`

Reconnect не створює нову session, якщо існуюча ще валідна. `renew` не створює session, а лише перевидає access token. 

Multi-session semantics:

- один user може мати кілька активних session
- session є runtime інстансами клієнтів (наприклад, різні пристрої)
- state типу `read cursor` є user-scoped і спільний між session
- state типу `last_seq` є session-scoped і може відрізнятись між session

## Token Model

- `accessToken` прив’язаний до конкретної session
- `refreshToken` прив’язаний до device/client

Наслідки:
- revoke access token інвалідує одну session
- revoke refresh token може інвалідувати всі session device/client. 

## Delivery, Replay and Recovery

### Delivery Guarantees

Базова модель:
- at-least-once
- idempotency required
- exact-once не гарантується

`received`, `delivered`, `read` є application-level подіями, а не transport-level exact-once гарантією. 

### Replay

Клієнт зберігає `last_seq` і після reconnect виконує replay через `EventQuery(after = last_seq)`.

Сервер повертає події з `seq > after`.  
Replay гарантує лише partial recovery. 

### Gap Handling

Сервер може мати retention policy і не зберігати всю історію подій.  
Якщо запитаний `after` вже старіший за мінімально доступний `seq`, виникає gap.

У цьому випадку сервер повертає:

`Query(type=error, code=gap)`

Після цього клієнт повинен виконати повний sync через snapshot/view queries, зокрема Inbox. 

## Consistency Model

Протокол не гарантує causal consistency.

Conflict resolution:
- last-write-wins за timestamp
- `delete` має пріоритет над `edit` / `update`

Клієнт повинен:
- обробляти дублікати
- коректно переносити reorder
- виконувати reconciliation локального стану. 

## Message State Semantics

Цей розділ визначає семантику стану повідомлення в CHAT.

### Core principle

Event є єдиною runtime-істиною.

Стан повідомлення не зберігається як окреме джерело істини, а виводиться з потоку подій.

message_state = fold(message_events)

---

### Payload

- повідомлення має структурований payload
- payload є частиною message state
- body є лише одним із полів payload
- коротка форма повідомлення є скороченням structured payload

Приклад:

"hi" == { body: "hi" }

---

### Edit semantics

- edit змінює стан існуючого повідомлення
- edit не створює новий message
- edit може змінювати окремі поля payload
- поля, не згадані в edit, залишаються без змін

---

### Delete semantics

- delete змінює current visible state повідомлення на deleted
- delete не створює новий message
- delete перекриває активний content state, включно з попередніми edit

---

### Replay semantics

- replay не є окремим джерелом істини
- replay має бути узгоджений з edit/delete semantics
- після застосування релевантних подій replay має приводити до того самого фінального стану повідомлення

---

### Invariants

- повідомлення має один поточний стан
- цей стан визначається потоком подій
- різні recovery-шляхи не повинні давати різний current payload

---

### Notes

- payload є state, а не просто даними повідомлення
- edit/delete визначають state, а не створюють нові повідомлення
- replay повинен конвергувати до того самого стану, що і звичайна обробка подій


## Feed Model

Feed — це логічний контекст доставки й упорядкування.  
Підтримуються типи:
- private
- chan
- mailbox
- group

`seq` існує тільки в межах feed.  
Глобального порядку між feed не існує. 

## Snapshot vs Stream

Протокол явно розрізняє дві моделі:

### Stream model
`Event` + `seq`

Це append-only лог подій у межах feed.

### Snapshot/view model
`Query` + `continuation`

Це стан або view-дані:
- inbox
- roster
- search
- conference
- member

Між stream і snapshot не гарантується повна консистентність у будь-який момент часу. 

### Feed View Model

FeedViewItem є агрегованою view/snapshot моделлю для:
- private feeds
- group feeds
- channel feeds
- mailbox feeds

FeedViewItem може містити:
- preview message
- headSeq
- readSeq
- unread
- mention-derived state

FeedViewItem не є джерелом істини для:
- Message state
- Conference state
- Subscription state

## Pagination Model

Для snapshot/view queries використовується:
- `limit`
- `continue` (opaque continuation token)

Pagination:
- не гарантує snapshot isolation
- може повертати дублікати
- може пропускати елементи при зміні даних між сторінками

Для Event replay використовується окрема seq-based модель:
- `after`
- `limit`
- `nextAfter`
- `hasMore`. 

## Read / Unread Model

`read` інтерпретується як cursor, а не як набір message ids.

Read cursor:
- є user-scoped (per feed)
- спільний для всіх session одного користувача
- оновлюється через read operation з будь-якої session

### Read as boundary

Read інтерпретується як верхня межа (boundary) у feed, а не як набір message ids.

Тобто read означає:

read_cursor(user, feed) = N

де N є максимальним seq, який вважається прочитаним.

Ця семантика узгоджується з DSL формою:

- `send read for last`
- `query cursor read ... up to <seq>`

Read:

- є монотонним (не зменшується)
- не залежить від повноти delivery або replay
- може обганяти фактичну доставку повідомлень у конкретну session

Unread:
- є derived view відносно user-level read cursor
- не є глобальним source of truth
- може кешуватися або агрегуватися на рівні session/device

Базова формула:

`unread = current_seq(feed) - read_cursor(user)`

### Read invariants

- read cursor є монотонним:
  нове значення не може бути меншим за попереднє

- повторний read з меншим seq ігнорується

- read cursor не повинен ламатись через:
    - reorder event delivery
    - delete/edit mutation

Unread і mention-derived поля належать до feed view layer
(наприклад FeedViewItem), а не до canonical Conference state.
Агрегація unread до рівня device або користувача є server-side policy. 

## Mention View Model

Mention-derived state є feed-level view, а не canonical domain state.

Mention view:
- є user-scoped
- виводиться з message/event stream
- може залежати від mention-targeting semantics payload
- може кешуватися або агрегуватися для bootstrap/home/UI

Mention view може містити:
- count
- latestSeq
- messageId

Такі дані належать до FeedViewItem, а не до Conference state.

Mention state:

- є view-level агрегатом
- не є частиною canonical message або event state
- може містити посилання на конкретне повідомлення (через message id / seq)

Це узгоджується з DSL:
- mention не є окремою подією, яка змінює state
- це derived view поверх event stream

## Presence / Typing Model

Presence і typing передаються через Event.

Сервер може:
- throttle typing
- debounce presence
- aggregate read/delivered events

Ці оптимізації не змінюють семантику стану, а лише оптимізують доставку. 

## Federation and Routing

Кожен feed має authoritative broker/server, який відповідає за:
- порядок подій
- seq
- retention / replay policy

Проміжні broker:
- можуть форвардити пакети
- можуть додавати transport metadata
- не повинні змінювати payload

Routing виконується через transport-level headers, а не через зміну domain payload. 

## Security Model

TLS захищає transport channel між сусідніми вузлами, але не гарантує end-to-end недоторканність payload.

Trust boundaries:
- headers є transport-level metadata
- payload є domain-level data
- проміжні broker не повинні змінювати payload

Payload model:
- `Message.payload`
- `Event.payload`
- certificate-related data
- CMS-like content

усе це передається як opaque binary, якщо не задано інше на рівні application/crypto layer. 

## Versioning and Capabilities

Кожне повідомлення має `vsn` — wire version.

Version negotiation виконується під час authenticate:
- клієнт може передати `supportedVsn`
- сервер може повернути `selectedVsn`

Capabilities / optional features узгоджуються окремо через `Feature` model.  
Невідомі extension fields і capabilities повинні ігноруватись. 

## Summary

CHAT v2 — це:
- transport-oriented messaging protocol
- session-aware event stream model
- query-driven state/snapshot model
- at-least-once delivery system
- feed-scoped ordering protocol
- architecture, що не змішує transport, runtime events, state views і crypto/application payload. 