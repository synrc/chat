# SPEC

CHAT v2 Specification

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

### Access policy and ABAC

Протокол не визначає політику доступу як частину canonical state.

Access control (зокрема ABAC — attribute-based access control)
розглядається як окремий policy layer поверх protocol model.

Цей layer визначає:

- чи дозволена дія (send, edit, delete, read, query)
- які ресурси доступні (feeds, messages, members, roster)
- які частини view видимі (payload fields, mentions, unread aggregates)

ABAC не змінює:

- Message state
- Event stream
- feed ordering (`seq`)
- replay semantics
- read cursor як canonical truth

Тобто:

- протокол визначає істину (truth)
- policy layer визначає доступ до цієї істини

Деталі моделі доступу та policy evaluation описані в ARCH-AUTH.md.

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

### Message state derivation

Стан повідомлення визначається як результат послідовного застосування подій
(MessageEvent) до початкового payload повідомлення.

Початковий стан:

- initial_state = Message.payload

Функція переходу стану визначається як:

- apply(edited, state):
  - якщо state.deleted == true → no-op
  - інакше → оновлює змінювані поля (наприклад body)

- apply(updated, state):
  - якщо state.deleted == true → no-op
  - інакше → замінює або мерджить поля відповідно до semantics update

- apply(deleted, state):
  - встановлює state.deleted = true
  - payload стає невидимим

Фінальний стан повідомлення:

    final_state = fold(apply, events)

де events — це впорядкований набір подій відповідно до правил ordering /
conflict resolution протоколу.


### Replay convergence

Replay і online-обробка повинні приводити до одного і того самого
фінального стану повідомлення.

Ця вимога є окремим випадком загальних message state invariants.

---

### Replay semantics

- replay не є окремим джерелом істини
- replay має бути узгоджений з edit/delete semantics
- після застосування релевантних подій replay має приводити до того самого фінального стану повідомлення

---

### Invariants

- повідомлення має один поточний стан

- цей стан визначається потоком подій

- replay і online-обробка повинні приводити до одного і того самого фінального стану

- різні recovery-шляхи не повинні давати різний current payload

- delete домінує:
  після delete повідомлення не може знову стати видимим,
  навіть якщо пізніше застосовуються старі edit/update

- edit/update не створюють новий Message:
  вони змінюють стан існуючого повідомлення

- дублікати подій не повинні створювати кілька видимих станів
  (ідемпотентність застосування)

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

## View Model

Протокол розрізняє окремий шар view поверх canonical state.

View:

- не є джерелом істини
- не змінює Message або Event state
- не впливає на replay semantics
- не є transport-level сутністю

View є результатом Query і може бути:

- snapshot
- projection
- derived

---

### View types

У протоколі використовуються два типи view:

#### Snapshot view

- inbox
- home

Властивості:

- представляє агрегований стан на момент запиту
- може використовуватись як recovery anchor (наприклад inbox або home)
- може мати snapshot boundary

---

#### Projection / List view

- roster
- search
- members
- moderation
- subscriptions
- conference list/get

Властивості:

- є projection або list/view над існуючим state
- не має snapshot anchor
- не використовується для recovery
- може повертати підмножину payload або paginated items

---

#### Derived view

- mentions
- unread aggregates
- presence-derived state

Властивості:

- виводиться з message/event stream
- не є частиною canonical state
- може кешуватись або агрегуватись

---

### View invariants

- Message/Event є єдиним джерелом істини
- View не змінює state
- View не впливає на read cursor
- View не впливає на replay boundary

- різні view можуть одночасно спостерігати різний стан
- view може бути частково застарілим (stale)

---

### Pagination semantics

View pagination використовує continuation model:

- `limit`
- `continue`

Інваріанти:

- pagination не створює новий state
- pagination не гарантує snapshot isolation
- можливі:
  - дублікати
  - пропуски
  - зміна window між сторінками

---

### Interaction with policy

View завжди проходить через policy layer:

- ABAC
- visibility
- moderation

Це означає:

- view не може відкривати inaccessible data
- filtering застосовується до view результату
- search, inbox, home повинні мати однакові visibility guarantees

---

### Relation to stream

Stream (`Event`) і View (`Query`) є незалежними шарами:

- stream визначає істину (truth)
- view є проекцією цієї істини

Жоден view не повинен:

- змінювати event stream
- змінювати ordering
- замінювати replay

---

### Summary

View model є окремим шаром поверх protocol:

- не змінює state
- не є джерелом істини
- не впливає на replay

але:

- визначає те, що клієнт бачить
- формує UX через projection і aggregation

### Feed View Model

FeedViewItem є агрегованою view/snapshot моделлю для:
- private feeds
- group feeds
- channel feeds
- mailbox feeds

FeedViewItem може містити:
- preview message
- headSeq
- read cursor
- unread
- mention-derived state

FeedViewItem не є джерелом істини для:
- Message state
- Conference state
- Subscription state

## Home / Bootstrap Model

`home` (або bootstrap) є агрегованим snapshot/view запитом,
який повертає початковий стан клієнта.

Home включає:
- roster
- feeds
- previews
- derived view state (unread, mentions тощо)

Home не є джерелом істини, а лише view поверх canonical state.

---

### Home snapshot

Home повертає `shared snapshot`, який є recovery anchor
для подальшого event replay.

Цей snapshot:

- є узгодженим зрізом (consistent cut) стану
- покриває всі feed, включені в home result
- використовується як opaque boundary для replay (`snapshot = anchor`)

---

### Home + Replay

Home і replay разом утворюють безшовний recovery механізм:

- replay після snapshot не повинен:
  - дублювати preview або snapshot дані
  - створювати gaps

- replay повинен повертати тільки події з `seq > snapshot`

- snapshot визначає нижню межу replay для кожного feed

---

### Multi-feed semantics

- snapshot є спільним (shared) для всіх feed у межах одного home запиту

- при цьому:
  - `seq` лишається feed-scoped
  - replay виконується окремо для кожного feed

- snapshot не означає, що всі feed мають однаковий seq,
  але гарантує узгоджений момент часу для recovery

---

### Home pagination

Якщо home повертається у кілька сторінок:

- всі сторінки повинні використовувати один і той самий snapshot

- pagination не повинна:
  - створювати новий snapshot boundary
  - змінювати recovery anchor

- snapshot є стабільним для всього paged home result

---

### Home is read-neutral

Home є view-операцією і не повинен змінювати state:

- не викликає read
- не змінює read cursor
- не впливає на unread
- не змінює subscription / roster

Home не повинен створювати побічних ефектів у protocol state

## Search Model

Search є query/view extension поверх protocol model.

Search:

- не змінює Message state
- не генерує Event
- не означає read
- не рухає replay cursor
- не є feed або event stream

Search result є projection/view над існуючим state,
аналогічно inbox/home/roster.

---

### Scope

Search виконується у межах видимого для користувача scope:

- peer (private feed)
- group (conference feed)
- global (union visible scopes)

Search:

- поважає membership
- поважає moderation policy
- не повинен leak-ати inaccessible scope через result

---

### Visibility and fields

Search:

- поважає message-level visibility (ABAC / classification)
- поважає field-level visibility

Інваріанти:

- hidden field => не searchable
- hidden requested field => не повертається у projection
- match сам по собі не дає доступу до resource

---

### Projection

Search підтримує projection через requested fields:

- результат може містити лише підмножину payload
- projection не змінює matching semantics
- projection не обходить visibility constraints

---

### Pagination

Search використовує continuation-based pagination:

- `limit`
- `continue`
- `hasMore`

Search pagination:

- не змінює read state
- не впливає на replay boundary
- є view-only операцією

---

### Ordering

Search result повертається у stable implementation-defined order.

Це означає:

- сервер визначає порядок items
- explicit sortBy/ranking не визначені на цьому етапі

Інваріанти:

- той самий query над незмінним result set
  повинен повертати items у тому самому порядку

- `continue` повинен продовжувати той самий order chain

- projection не повинна впливати на порядок items

---

### Consistency

Search не гарантує snapshot isolation:

- дані можуть змінюватись між сторінками
- result window може змінюватись
- можливі:
  - дублікати
  - пропуски

Search є eventually-consistent view,
а не стабільний snapshot.

---

### Relation to other views

Search відрізняється від:

- Inbox:
  - feed-scoped snapshot
  - може використовуватись для recovery

- Home:
  - multi-feed bootstrap snapshot
  - має snapshot anchor

Search:

- не має snapshot anchor
- не використовується для recovery
- є ad-hoc projection query

## Pagination Model

Pagination використовується для snapshot/view queries:

- `limit`
- `continue`

Snapshot pagination:

- не гарантує snapshot isolation
- може повертати дублікати
- може пропускати елементи

Event replay використовує окрему seq-based модель,
яка описана в `Event Replay Pagination Model`.

## Event Replay Pagination Model

Event replay використовує seq-based pagination:

- `after`
- `limit`
- `nextAfter`
- `hasMore`

Ця модель відрізняється від snapshot pagination і має власні інваріанти.

---

### Replay pagination invariants

Replay pagination повинна задовольняти наступні вимоги:

- події повертаються у порядку зростання `seq`

- кожна сторінка replay:
  - містить події з `seq > after`
  - не повинна містити події з `seq <= after`

- `nextAfter` визначає позицію для наступного запиту:
  - `nextAfter >= max(seq)` поточної сторінки
  - `nextAfter` є монотонним

---

### No overlap

Сторінки replay не повинні перекриватися:

- одна і та сама подія не повинна з'являтись у двох послідовних сторінках
- клієнт не повинен отримувати дублікати через pagination

Примітка:
- дублікати можливі через at-least-once delivery,
  але не повинні виникати як наслідок pagination logic

---

### No gaps (within retention)

За відсутності `gap`:

- replay не повинен пропускати події
- усі події з `seq > after` повинні бути доступні через послідовні сторінки

Якщо частина подій недоступна через retention policy:

- сервер повертає `error gap`
- клієнт повинен перейти до snapshot-based recovery

---

### Snapshot vs Replay

Snapshot pagination і replay pagination мають різну семантику:

Snapshot (`limit + continue`):

- не гарантує snapshot isolation
- може:
  - повертати дублікати
  - пропускати елементи
  - змінювати склад між сторінками

Replay (`after + nextAfter`):

- є строго впорядкованим по `seq`
- гарантує:
  - відсутність overlap
  - відсутність gaps (крім explicit gap error)

---

### Snapshot drift

Між snapshot сторінками можуть відбуватись зміни:

- нові повідомлення можуть з'являтись
- старі можуть зникати або змінюватись

Це означає:

- snapshot не є стабільним зрізом
- continuation token не гарантує той самий набір даних

Для консистентного recovery:

- клієнт повинен використовувати snapshot як anchor
- і переходити до replay (`snapshot = anchor`)

---

### Interaction with Home

Home bootstrap задає `shared snapshot`,
який використовується як початкова точка для replay.

Replay pagination після home:

- повинна починатися з `seq > snapshot`
- не повинна дублювати preview/snapshot дані
- повинна залишатися узгодженою з multi-feed semantics

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

### Partial read semantics

Read cursor відображає лише observed boundary, а не повний стан feed.

Це означає:

- read може виконуватись після часткового replay (partial delivery)
- read не вимагає повного отримання всіх подій у feed

---

### Observed boundary

Якщо клієнт отримав лише частину подій:

- read cursor оновлюється до максимально спостереженого `seq`
- події з більшим `seq`, які ще не були доставлені, лишаються unread

Формально:

- read_cursor <= max_observed_seq

---

### Partial replay interaction

У випадку partial replay:

- `send read for last` означає read до останнього локально отриманого повідомлення
- це не означає read до head feed

Наслідок:

- remaining tail повинен бути доступний через наступний replay
- replay після cursor може повертати ще події

---

### Unread after partial read

Unread визначається відносно read cursor, а не відносно delivery:

- якщо read виконано після partial replay:
  - старіші події вважаються read
  - новіші події (включно з ще не доставленими) лишаються unread

---

### Future events

Read не фіксує feed:

- нові події з `seq > read_cursor` автоматично формують новий unread tail
- read не впливає на події, які з'являються після нього

---

### Invariants

- read не може "закрити" feed без повного replay
- read не повинен позначати як read події, які клієнт не спостерігав
- unread tail завжди визначається як:

  unread = current_seq(feed) - read_cursor

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
- message id

Такі дані належать до FeedViewItem, а не до Conference state.

Mention state:

- є view-level агрегатом
- не є частиною canonical message або event state
- може містити посилання на конкретне повідомлення (через message id / seq)

Це узгоджується з DSL:
- mention не є окремою подією, яка змінює state
- це derived view поверх event stream

### Mention source conditions

Mention-derived state виникає не з будь-якого message,
а лише з message, який одночасно:

- видимий для поточного user
- входить до unread області feed
- містить mention цього user у payload/context

Це означає:

- hidden message не повинен породжувати visible mention state
- replay без explicit read не очищає mention state
- mention cleared semantics визначається read boundary,
  а не самим фактом delivery або replay

### Mention semantics

Mention є derived сигналом, а не частиною canonical state.

Це означає:

- mention не створює окремих подій
- mention не змінює message state
- mention не впливає на replay або ordering

Mention визначається виключно payload + context.

---

### Mention detection

Mention виникає, якщо payload повідомлення містить посилання на user:

- explicit (наприклад `@user`)
- або через structured payload (наприклад поле `mentions`)

Сервер може інтерпретувати mention:

- під час ingestion message
- або під час побудови view

---

### Mention as view

Mention state:

- є user-scoped
- є feed-scoped
- не є частиною canonical message/event state

Це означає:

- mention може кешуватись
- mention може агрегуватись
- mention може змінюватись без зміни underlying event stream

---

### Interaction with read

Mention не є незалежним від read:

- якщо message.seq <= read_cursor:
  - mention не повинен вважатися активним

- якщо message.seq > read_cursor:
  - mention входить в unread mention set

Тобто:

mention_unread ⊆ unread

---

### Interaction with visibility

Mention visibility підпорядковується тим самим policy rules,
що і visibility message/view source.

Це означає:

- якщо message hidden для user,
  mention-derived state від цього message не повинен бути видимим

- якщо message видимий частково,
  mention state може існувати тільки тоді,
  коли policy допускає видимість самого mention source
  у feed/home view

Mention не повинен бути side-channel,
через який клієнт дізнається про hidden message.

---

### Interaction with replay

Replay не повинен окремо “відновлювати” mention:

- mention повинен автоматично виводитись із replay event stream
- replay не повинен містити спеціальних mention-подій

---

### Interaction with delete/edit

Оскільки mention є derived:

- delete повідомлення:
  - видаляє mention із view

- edit повідомлення:
  - може:
    - додати mention
    - видалити mention

- replay після edit/delete повинен давати той самий mention state

---

### Invariants

- mention не є частиною canonical state
- mention не повинен впливати на replay semantics
- mention не повинен створювати окремих event
- mention завжди узгоджений з:
  - message payload
  - read cursor

## Presence / Typing Model

Presence і typing передаються через Event.

Сервер може:
- throttle typing
- debounce presence
- aggregate read/delivered events

`typing` є transient runtime event, а не stable state snapshot.

Тобто:
- `typing` не повинен зберігатися в home або інших stable view
- `typing` не повинен повторно з'являтися в replay без нового runtime source

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
