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
Message є ідемпотентним через глобально унікальний `Message.id`.  
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
- `read cursor`

Session lifecycle:
- створюється через `Authority.authenticate`
- може бути відновлена після reconnect
- може бути `active`, `expired`, `revoked`

Reconnect не створює нову session, якщо існуюча ще валідна. `renew` не створює session, а лише перевидає access token. 

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

`Query(type=error, code=gapDetected)`

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

Unread:
- є session-scoped
- не є глобальним станом користувача
- є derived/cache view

Базова формула:

`unread = current_seq(feed) - read_cursor(session)`

Поле `Conference.unread` не є source of truth.  
Агрегація unread до рівня device або користувача є server-side policy. 

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