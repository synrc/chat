# SPEC

CHAT v2 Specification

## Overview

CHAT v2 — це messaging/pub-sub протокол з чітким розділенням між transport-пакетами, runtime-подіями, моделлю state/view та керуванням auth/session. Протокол побудований так, щоб одна семантика не мала кількох паралельних шляхів на wire-рівні. 

Основні transport-рівневі сутності:
- Message — тільки контент повідомлення
- Event — всі runtime події
- Query — єдиний request/response механізм
- Authority — auth, session і trust/bootstrap

## Design Principles

1. Одна семантика — один wire-шлях.
2. Message не містить lifecycle/runtime-семантики.
3. Event є єдиним каналом runtime-подій.
4. Query є єдиним request/response шаром для control/state.
5. Domain state і view не є top-level типами packet. 

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
- інші runtime-зміни стану

Події мають `seq`, який:
- монотонно зростає
- визначений тільки в межах feed

Event delivery model:
- at-least-once
- можливі дублікати
- можливий reorder
- causal ordering не гарантується. 

### Event as runtime truth

Event є єдиним джерелом runtime-істини.

Message state не є окремо збереженою істиною,
а виводиться як:

message_state = fold(events)

Це означає:

- edit/delete не створюють новий message
- вони змінюють стан існуючого message
- replay повинен конвергувати до того самого фінального стану

Ця модель узгоджується з DSL сценаріями:
- delete overrides edit
- replay повертає фінальний стан
- event ordering може бути некаузальним, але стан має бути узгодженим

### Query

Query є єдиним механізмом для:
- отримання стану
- commands
- recovery
- paging
- error signaling

Типи Query:
- get
- set
- result
- error. 

### Transport batching

Transport framing може нести або один packet, або batch із кількох packet.

Batch:
- є transport/coalescing-оптимізацією
- зберігає порядок packet усередині batch
- не є atomic transaction
- не створює shared snapshot або shared command context

Практично це використовується для:
- client-side pipelining кількох request
- server-side coalescing кількох event/result packet

Якщо потрібна compound або atomic semantics, вона повинна бути змодельована
окремою protocol feature, а не самим batch envelope.

### Authority

Authority відповідає за:
- authenticate
- renew
- revoke
- enroll
- trust/bootstrap-семантику

Authority може виступати як:
- auth/session authority
- registration authority
- certification authority

Протокол не виконує розбір або перевірку PKIX/CMS payload на своєму рівні; дані, пов'язані з сертифікатами, передаються як opaque binary.

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

- протокол визначає істину
- policy layer визначає доступ до цієї істини

Деталі моделі доступу та policy evaluation описані в ARCH-AUTH.md.

## Session Model

Протокол розділяє:
- Identity
- Device
- Session

Session:
- не є transport-з'єднанням
- не є користувачем
- є активним інстансом клієнта
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
- session є активними інстансами клієнтів (наприклад, різні пристрої)
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

`received`, `delivered`, `read` є подіями application-рівня, а не transport-рівневою exact-once гарантією.

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
- коротка форма повідомлення є скороченням структурованого payload

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

- delete змінює поточний видимий стан повідомлення на deleted
- delete не створює новий message
- delete перекриває активний вмістовний стан, включно з попередніми edit

---

### Message state derivation

Стан повідомлення визначається як результат послідовного застосування подій
(MessageEvent) до початкового payload повідомлення.

Початковий стан:

- initial_state = Message.payload

Функція переходу стану визначається як:

- apply(edited, state):
  - якщо state.deleted == true → без змін
  - інакше → оновлює змінювані поля (наприклад body)

- apply(updated, state):
  - якщо state.deleted == true → без змін
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

- різні recovery-шляхи не повинні давати різний поточний payload

- delete домінує:
  після delete повідомлення не може знову стати видимим,
  навіть якщо пізніше застосовуються старі edit/update

- edit/update не створюють новий Message:
  вони змінюють стан існуючого повідомлення

- дублікати подій не повинні створювати кілька видимих станів
  (ідемпотентність застосування)

---

## Feed Model

Feed — це логічний контекст доставки й упорядкування.  
Підтримуються типи:
- private
- chan
- mailbox
- group

`seq` існує тільки в межах feed.  
Глобального порядку між feed не існує. 

## View Model

Протокол явно розрізняє дві моделі:

### Stream model
`Event` + `seq`

Це лог подій у межах feed, до якого події лише додаються.

### Snapshot/view model
`Query` + `continuation`

Це стан або view-дані:
- inbox
- roster
- search
- conference
- member

Між stream і snapshot не гарантується повна консистентність у будь-який момент часу.

Протокол розрізняє окремий шар view поверх canonical state.

View:

- не є джерелом істини
- не змінює Message або Event state
- не впливає на replay semantics
- не є сутністю transport-рівня

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

- є projection або list/view над наявним state
- не має snapshot anchor
- не використовується для recovery
- може повертати підмножину payload або елементи частинами

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
- view може бути частково застарілим

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
  - зміна вікна між сторінками

---

### Interaction with policy

View завжди проходить через policy layer:

- ABAC
- visibility
- moderation

Це означає:

- view не може відкривати недоступні дані
- filtering застосовується до результату view
- search, inbox, home повинні мати однакові правила видимості

---

### Relation to stream

Stream (`Event`) і View (`Query`) є незалежними шарами:

- stream визначає істину
- view є проекцією цієї істини

Жоден view не повинен:

- змінювати event stream
- змінювати ordering
- замінювати replay

---

### Feed View Model

FeedViewItem є агрегованою view/snapshot-моделлю для:
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
- derived view-стан (unread, mentions тощо)

Home не є джерелом істини, а лише view поверх canonical state.

### Home invariants

- `home` повертає `shared snapshot`, який є recovery anchor
  для подальшого replay (`snapshot = anchor`)
- snapshot є спільним для всіх feed у межах одного home запиту
- replay після `home` повертає тільки події з `seq > snapshot`
- усі сторінки paged `home` повинні використовувати один і той самий snapshot
- `home` є view без побічного впливу на read:
  - не викликає read
  - не змінює read cursor
  - не впливає на unread
  - не змінює subscription / roster

### Search as projection view

Search є query/view extension поверх protocol model.

Search:

- не змінює Message state
- не генерує Event
- не означає read
- не рухає replay cursor
- не є feed або потоком event

Search result є projection/view над наявним state,
аналогічно inbox/home/roster.

### Search invariants

- search виконується у видимому для користувача scope:
  - peer
  - group
  - global
- search поважає membership, moderation і field-level visibility
- hidden field не бере участі в search і не повертається у projection
- projection не змінює matching semantics і не обходить visibility constraints
- search використовує continuation pagination, але:
  - не змінює read state
  - не впливає на replay boundary
  - не має snapshot anchor
  - не використовується для recovery
- порядок result set є стабільним і задається реалізацією
- search не гарантує snapshot isolation:
  можливі дублікати, пропуски і зміна вікна між сторінками

### Pagination and Replay Windows

Pagination використовується для snapshot/view queries:

- `limit`
- `continue`

Snapshot pagination:

- не гарантує snapshot isolation
- може повертати дублікати
- може пропускати елементи

Event replay використовує окрему seq-based модель:

- `after`
- `limit`
- `nextAfter`
- `hasMore`

### Replay pagination invariants

- replay повертає події у порядку зростання `seq`
- кожна сторінка містить тільки події з `seq > after`
- `nextAfter` є монотонним і продовжує той самий ланцюжок replay
- replay pagination не повинна створювати overlap між сторінками
- за відсутності `gap` replay не повинен пропускати події
- якщо частина історії недоступна через retention policy,
  сервер повертає `error gap`, а клієнт переходить до recovery через snapshot
- snapshot pagination і replay pagination мають різну семантику:
  - snapshot pagination може давати дублікати, пропуски і зсув між сторінками
  - replay pagination задає строго впорядковане продовження за `seq`
- після `home` replay повинен починатися з `seq > snapshot`
  і не дублювати snapshot/preview дані

## Read / Unread Model

`read` інтерпретується як cursor, а не як набір message ids.

Read cursor:
- є user-scoped (per feed)
- спільний для всіх session одного користувача
- оновлюється через read operation з будь-якої session

### Read invariants

- read є явно заданою межею:
  `read_cursor(user, feed) = N`
- read cursor є user-scoped, а не session-scoped
- повторний read з меншим `seq` є валідним відмотуванням назад
- read cursor відображає спостережувану межу:
  read не вимагає повного replay і не позначає як read події,
  які клієнт не спостерігав
- `unread` є derived view відносно read cursor, а не окремим джерелом істини
- нові події з `seq > read_cursor` формують новий unread tail
- unread і mention-derived поля належать до шару feed view,
  а не до canonical Conference state

### Mention as derived view

Mention-derived state є feed-рівневим view, а не canonical domain state.

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

### Mention invariants

- mention є derived сигналом, а не частиною canonical state
- mention не створює окремих event і не впливає на replay або ordering
- source mention визначається через payload і context:
  - явний mention (`@user`)
  - або canonical structured field `mentions`
- DSL short form `mention: <user>` є скороченням для canonical payload shape
- mention виникає тільки для message, який одночасно:
  - видимий для поточного user
  - входить до unread області feed
  - містить mention цього user
- `mention_unread ⊆ unread`
- replay не містить спеціальних mention-подій:
  mention автоматично виводиться з event stream
- delete видаляє mention із view, а edit може додати або прибрати mention
- mention не повинен бути побічним каналом для hidden message

## Presence / Typing Model

Presence і typing передаються через Event.

Сервер може:
- throttle typing
- debounce presence
- aggregate read/delivered events

`typing` є короткоживучою runtime-подією, а не stable state snapshot.

Тобто:
- `typing` не повинен зберігатися в home або інших stable view
- `typing` не повинен повторно з'являтися в replay без нового джерела runtime-події

Ці оптимізації не змінюють семантику стану, а лише оптимізують доставку.

## Federation and Routing

Кожен feed має authoritative broker/server, який відповідає за:
- порядок подій
- seq
- retention / replay policy

Проміжні broker:
- можуть форвардити пакети
- можуть додавати transport-метадані
- не повинні змінювати payload

Routing виконується через transport-рівневі headers, а не через зміну domain payload. 

## Security Model

TLS захищає transport-канал між сусідніми вузлами, але не гарантує end-to-end недоторканність payload.

Trust boundaries:
- headers є transport-рівневими метаданими
- payload є domain-рівневими даними
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
- архітектура, що не змішує transport, runtime events, state views і crypto/application payload. 
