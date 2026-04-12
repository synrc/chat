# DSL-CORE

Базова модель сценарного DSL для опису протоколу

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
query events feed private:bob after 100 limit 10
expect inbound message from alice body "hi"
```

- точний контроль
- ближче до протоколу

## Influences and Related Approaches

Цей DSL є scenario-based executable specification
для messaging / pub-sub протоколу.

Він поєднує кілька усталених підходів:

- Gherkin (Cucumber BDD)
  - структура сценаріїв (scenario / given / when / expect)
  - опис поведінки через дії та очікування

- SQL
  - декларативний стиль опису стану і запитів

- Citrus Framework (messaging testing)
  - multi-actor сценарії
  - send / expect semantics для messaging систем

- Scenario-based specification у distributed systems
  (Z notation, protocol testing DSL, consensus testing frameworks)
  - state-based modeling
  - explicit scenario description для edge cases і recovery

---

DSL не є новою формальною мовою,
а є executable specification layer поверх протоколу.

Це domain-specific поєднання цих підходів,
адаптоване для:

- multi-session / multi-device поведінки
- replay і snapshot semantics
- cursor-based read
- conflict resolution (edit / delete)
- protocol-level edge cases

---

### Argument rules

DSL використовує два стилі: short і exact.

#### Session context

- `session <alias>` перемикає поточний actor/session context сценарію
- усі наступні команди та очікування інтерпретуються від імені цієї session,
  доки контекст не буде змінено наступною командою `session <alias>`
- alias resolution для private feed (`query inbox/events/read <peer>`) залежить
  від поточного session context
- `session <session_alias> as <user_alias>` явно прив'язує session handle до user principal
- різні session alias можуть посилатися на того самого user:
  - `session bob1 as bob`
  - `session bob2 as bob`
- це використовується для multi-session сценаріїв, де state є user-scoped, а не session-scoped
- якщо `as <user_alias>` не вказано, то `session <alias>` є скороченням для випадку,
  де session alias і user alias збігаються

```text
session bob1 as bob
connect
auth

session bob2 as bob
connect
auth
```

#### Reference kinds

DSL розрізняє три типи посилань:

- `peer <user>` — приватний peer context відносно поточної session
- `group <name>` — group resource / group feed за назвою group
- `feed <token>` — явний feed identifier без alias resolution

Приклади:

- `query inbox peer bob`
- `query events peer bob after cursor`
- `query cursor read peer alice up to 123`
- `query inbox group room1`
- `query events group room1 after snapshot`
- `query cursor read group room1 up to 5`
- `query inbox feed private:bob`
- `query events feed private:bob after cursor`
- `query cursor read feed private:alice up to 123`

Canonical форма може використовувати `peer` / `group` як typed sugar.
Exact форма використовує `feed <token>` там, де потрібна protocol-level точність.

#### Short style

- команда може мати один основний позиційний аргумент
- тип цього аргументу визначається оператором (message/inbox/events/read)
- усі додаткові параметри задаються через ключові слова
- canonical DSL не використовує числові seq значення для read
- числові позиції використовуються тільки в exact формі

Приклади:

- `send message to bob "hi"` — `bob` інтерпретується як target alias
- `query inbox peer bob` — `peer bob` інтерпретується як private feed alias за peer alias
- `query events peer bob after 100 limit 10` — `peer bob` інтерпретується як private feed alias за peer alias
- `query inbox group room1` — `group room1` інтерпретується як group feed resource
- `send read for last` — read у дефолтному/поточному feed контексті
- `send read peer alice for last` — read у private peer feed context
- `send read group room1 for last` — read у group feed context
- `send read feed private:alice for last` — read у явно вказаному feed
- `add bob to roster` — додати bob у roster (створити односторонній зв’язок)
- `remove bob from roster` — видалити bob з roster (прибрати односторонній зв’язок)
- `query roster` — отримати поточний список контактів користувача


#### Exact style

- тип ресурсу задається явно
- alias розгортаються у повну форму
- exact форма використовується там, де потрібна точна protocol-level семантика

Для exact form поточний actor за замовчуванням береться з `session <alias>`,
тому його не потрібно дублювати явно в кожній команді,
якщо це не потрібно для спеціального розбору сценарію.

Приклади:

- `query inbox feed private:bob`
- `query events feed private:bob after 100 limit 10`
- `query inbox feed group:room1`
- `query events feed group:room1 after snapshot`
- `query cursor read feed private:alice up to 123`

#### Structured message form

Canonical short form для простих chat-сценаріїв лишається базовою формою:

```text
send message to bob "hi"
```

Окремо DSL може підтримувати розширену explicit форму
для структурованого payload без заміни canonical syntax:

```text
send message to bob {
  body: "hi"
}
```

```text
send message to bob {
  subject: "ERP/1 Document Draft"
  body: "Please review the attached Order 40 document."
  priority: high
}
```

Така форма:
- не замінює canonical short form
- використовується для richer payload semantics
- потрібна для document/message field scenarios
- є природним розширенням Message payload model

Structured payload у DSL інтерпретується на application/domain level.

Тобто DSL працює не з transport-level opaque binary payload як таким,
а з його прикладною структурованою інтерпретацією у вигляді fields / values.

Це дозволяє виражати document-like сценарії,
не фіксуючи конкретний wire encoding або crypto/container format.

На цьому етапі structured form фіксується як частина DSL semantics
і підтримується runner для message/payload scenarios.

#### Structured field values

У structured message form поле задається як `name: value`.

Мінімальний набір значень на цьому етапі:

- string
- integer
- boolean
- atom / enum

Приклади:

```text
send message to bob {
  body: "hi"
  amount: 1000
  urgent: true
  priority: high
}
```

Правила:

- імена полів у межах одного block мають бути унікальними
- порядок полів не має semantic значення
- `body` є звичайним field і не має спеціального статусу всередині structured block
- nested objects, arrays, attachments і binary payload поки що не фіксуються в базовій моделі

Невалідні приклади explicit identity у `given`:
```
given
  private feed alice<->bob has messages
  1 id "msg-123" from alice "m1"
  2 id "msg-123" from bob "m2"
```
- duplicate explicit id у seeded world state є невалідним
```
given
  private feed alice<->bob has messages
  1 id "msg-123" as m1id from alice "m1"
  2 id "msg-124" as m1id from bob "m2"
```
- duplicate seeded alias у `given` є невалідним
- такі помилки є validation failure of given state, а не runtime error badRequest

#### Structured payload validation

Для `send message to <target> { ... }` діють такі базові validation rules:

- duplicate field name -> `error badRequest`
- field `body` є обов'язковим
- field `body` повинен бути string
- nested object values не підтримуються і відхиляються
- array values не підтримуються і відхиляються
- unsupported value forms відхиляються як `error badRequest`

Приклади невалідних form:

```text
send message to bob {
  body: "x"
  body: "y"
}
```

```text
send message to bob {
  subject: "Draft"
}
```

```text
send message to bob {
  body: 42
}
```

```text
send message to bob {
  body: "x"
  meta: {}
}
```

```text
send message to bob {
  body: "x"
  tags: []
}
```

#### Message normalization

Short message form повинна нормалізуватись у structured form.

Приклад:

```text
send message to bob "hi"
```

нормалізується у:

```text
send message to bob {
  body: "hi"
}
```

Тобто short form є sugar над мінімальною structured form
з одним полем `body`.

Structured form не змінює базову семантику `send message`,
а лише робить payload явним і придатним для field-based сценаріїв.

#### Structured expect form

Окрім short expect form, DSL надалі може підтримувати
розширену expect form для structured payload.

Short form:

```text
expect message from alice body "hi"
```

Майбутня structured form:

```text
expect message from alice {
  body: "hi"
  subject: "Draft"
}
```

На цьому етапі structured expect form є частиною DSL semantics
і підтримується runner для partial payload matching та field-based scenarios.

#### Event expect form

DSL підтримує exact expect form для protocol-level event observation.

Canonical форма:

```
expect event message read bob up to 12
expect event message deleted alice id m1id
expect event typing bob
```
Для presence events canonical DSL може опускати family `presence`,
якщо event type є однозначним.

Наприклад:

- `expect event offline bob`
- `expect event typing bob`

Це sugar над explicit form:

- `expect event presence offline bob`
- `expect event presence typing bob`

Якщо event type потенційно двозначний,
потрібно використовувати explicit form з family.
Для presence scope це означає:

- canonical / exact form описує actor як user principal
- session-level деталі можуть бути важливі для runtime model,
  але `online` / `offline` за замовчуванням інтерпретуються як user-scoped aggregate facts

У цій формі:

- перший позиційний аргумент після event family/type інтерпретується як actor
- `up to <seq>` є natural DSL формою для read cursor
- `id` є protocol identity reference (через capture id as або given)

Actor є опціональним.

Можливі варіанти:

```
expect event message read bob up to 12
expect event message read up to 12
```

Якщо actor не вказаний:
- DSL інтерпретує це як wildcard match
- подія може бути від будь-якого actor

Exact (explicit) форма також допускається:

```
expect event message read actor bob seq 12
```

Exact форма:
- використовується для protocol-level точності
- не є основною canonical DSL формою

Event expect form:

- описує server-observable Event
- не означає client-originated command
- використовується для replay / runtime semantics перевірки

Event expect form узгоджується з protocol model:

- MessageEvent (delivered/read/edited/deleted)
- PresenceEvent (online/offline/typing)

#### Presence runtime surface (minimal)

На цьому етапі DSL фіксує presence як protocol-observable event layer,
а не як message/feed item.

Мінімальний runtime surface для presence:

- `disconnect`
  - створює presence fact типу `offline`
  - actor = поточна session / current user

Мінімальний expect surface для presence:

Canonical:

- `expect event offline <user>`
- `expect event offline`

Exact:

- `expect event presence offline <user>`
- `expect event presence offline`

Canonical presence form є sugar над exact presence form.

Правила:

- якщо actor вказаний явно:
  - expectation перевіряє exact actor match

- якщо actor не вказаний:
  - expectation використовує wildcard match
  - важливий сам факт presence event, а не конкретний actor

На цьому етапі DSL фіксує мінімальний runtime source для:

- `disconnect`
  - створює `offline`, якщо закрилась остання active session user

- `connect`
  - створює `online`, якщо це перша active session після fully-offline state

- `reconnect`
  - еквівалентний `connect` для presence semantics

Presence event semantics:

- presence event є окремим від message replay items
- presence event не змінює message history
- presence event не означає `read`
- presence event не змінює unread/home/snapshot state

#### Presence scope semantics

За замовчуванням DSL фіксує таку модель scope:

- `online` / `offline` є user-scoped aggregate presence
- `typing` є session-scoped transient presence

Це означає:

- якщо user має кілька одночасно активних session,
  disconnect однієї session сам по собі не означає `offline` для user

- `offline <user>` виникає лише тоді,
  коли закрилась остання активна session цього user

- `online <user>` виникає тоді,
  коли з'явилась перша активна session після fully-offline state

- `typing` не означає stable user state
  і не повинен інтерпретуватись як aggregate presence фактом

#### Message reference semantics

У canonical mutation form DSL розрізняє два способи посилання на повідомлення:

- `ref <value>` — DSL-level local reference
- `id <value>` — protocol-level message identity

Приклади:

```text
send message to bob "hi" capture id as m1id

edit message ref "m1" body "m1 edited"
delete message ref "m1"

edit message id m1id body "m1 edited"
delete message id m1id
```

`ref` використовується як semantic harness для зручного посилання
на раніше відоме повідомлення в межах сценарію.

Такий reference може збігатися з body або іншим упізнаваним локальним marker,
але не повинен тлумачитись як normative protocol identity.

Для protocol-level mutation identity DSL підтримує явне захоплення
message identity у локальний alias:

```text
send message to bob "hi" capture id as m1id
```

Тут `m1id` не є literal protocol id,
а є DSL alias, який зв'язується з згенерованим protocol-level message identity.

Після цього:

```text
edit message id m1id body "hi v2"
delete message id m1id
```

означає mutation за captured protocol identity,
а не за локальним `ref` marker.

Legacy форма:

```text
edit message "m1" body "m1 edited"
delete message "m1"
```

інтерпретується як sugar над:

```text
edit message ref "m1" body "m1 edited"
delete message ref "m1"
```

Protocol source of truth для identity лишається окремим від цього DSL sugar.

`ref`, `id` і `capture id as` фіксують різницю між:
- DSL reference
- captured protocol identity
- protocol-level mutation addressing

#### Mutation semantics

Операції `edit message` та `delete message` у DSL не означають створення окремого виду Message.

Вони описують mutation існуючого повідомлення і зміну його state.

На цьому рівні DSL виступає як semantic harness:
- `edit` і `delete` виражають зміну стану повідомлення,
  а не створення нового message.

У protocol-observable моделі це відповідає event-level семантиці:
- зміни повідомлення відображаються як події (events),
  а не як окремі message об’єкти.

Тобто:
- Message = intent / payload
- Event = runtime truth для mutation (edit/delete)

Остаточна wire / ASN.1 форма mutation command і mutation event
буде визначена окремо.

При цьому DSL вже фіксує protocol-observable semantics:
- mutation адресує існуюче message state;
- `ref` і `id` є різними addressing modes;
- `id` може бути отриманий через `capture id as`.

#### Default resolution

контекст команди визначає, як інтерпретується identifier

- у message context `bob` означає user/target alias
- `peer <user>` означає private peer feed context відносно поточної session
- `group <name>` означає group feed/resource context
- `feed <token>` означає explicit feed token без alias resolution
- `query inbox peer bob` = `query inbox feed private:bob`
- `query events peer bob after 100 limit 10` = `query events feed private:bob after 100 limit 10`
- `query cursor read peer alice up to 123` = `query cursor read feed private:alice up to 123`
- `query inbox group room1` = `query inbox feed group:room1`
- `query events group room1 after snapshot` = `query events feed group:room1 after snapshot`
- у `session alice` reference `peer bob` означає приватний feed alice ↔ bob,
  а у `session bob` reference `peer alice` означає той самий feed bob ↔ alice
- `query inbox continue` продовжує останній `query inbox ...` у межах того самого feed

#### Home bootstrap

DSL підтримує bootstrap/home query для початкового або reconnect sync.

Canonical:

- `bootstrap home`
- `bootstrap home limit 20`
- `bootstrap home limit 20 preview 1`

Exact:

- `query home`
- `query home limit 20 preview 1`
- `query home continue`

`bootstrap home` / `query home` означає snapshot/view запит для bootstrap стану клієнта.

Home result може містити:
- roster
- список FeedViewItem
- preview елементи для feed
- unread view state
- mention-derived view state
- continuation для pagination
- snapshot anchor для подальшого replay

Home query:
- не означає `read`
- не змінює roster relation
- не змінює message state
- не змішує relation і messaging authorization
- є view ресурсом для стартового стану клієнта

Home query повертає shared snapshot anchor для всього home result.

Цей anchor може використовуватись для подальшого replay,
наприклад через:
- `query events peer bob after snapshot`
- `query events group room1 after snapshot`
- `query events feed private:bob after snapshot`
   для будь-якого feed, вже покритих тим самим home result.

DSL допускає natural alias у short form, але exact інтерпретація завжди повинна зводитись до явного визначення feed або target.

DSL підтримує symbolic cursor значення:

- `cursor`
- `next`
- `snapshot`

`cursor` означає збережену replay position цієї session
- використовується для recovery після reconnect
- відповідає останньому відомому seq у feed для цієї session
- не залежить від локально отриманих подій у поточному replay
  `snapshot` означає snapshot anchor, отриманий з попереднього snapshot/view query.

`snapshot`, отриманий з `query inbox <feed>`, є feed-scoped recovery anchor
і використовується тільки для цього feed.

`snapshot`, отриманий з `query home`, є shared bootstrap anchor
для всіх feed, покритих тим самим home result.

При використанні в `query events ... after snapshot`
shared home snapshot інтерпретується як replay boundary
для конкретного feed у межах того самого home bootstrap context.
Такий replay є валідним тільки для feed, вже покритих тим самим home result.

`next` означає continuation cursor для наступної сторінки event replay

`last` означає останній seq, локально отриманий у цій session
- `last` не означає head feed
- `last` не означає повний replay
- `last` залежить від того, який обсяг подій був отриманий (preview / partial / full)

#### Seq terminology

У DSL `seq` означає feed-scoped порядкову позицію події або повідомлення.

У протокольному описі може також використовуватись термін `last_seq`
для позначення останньої збереженої replay position конкретної session.

Тобто:
- `seq` — feed-scoped порядкова позиція події або повідомлення
- `last_seq` — session-local replay position, що зберігає останній відомий `seq` для цієї session

DSL зазвичай використовує коротку форму `seq`,
оскільки вона достатня для сценарного опису.
У read/query form DSL може використовувати natural form `up to <seq>`,
де `seq` лишається числовою feed-scoped boundary координатою.

#### Expect semantics

- `expect authenticated` означає, що auth request завершився успішно
- `expect session created` означає, що створено нову session
- `expect same session` означає, що після `auth resume` відновлено попередню session
- `expect access token` означає, що auth result містить access token
- `expect access token refreshed` означає, що `renew` повернув новий access token
- `expect events non-empty` означає, що результат містить хоча б одну подію
- `expect not error unauthorized` означає, що запит не завершується auth-відмовою
- `expect more` означає `expect hasMore true`
- `expect not more` означає `expect hasMore false`
- `expect snapshot` означає, що inbox result містить recovery anchor (`snapshotSeq`)
- `expect empty replay` означає, що replay result не містить подій (`events = 0`)
- `expect no duplicates` означає, що результат не містить елементів, уже покритих попереднім snapshot або попередньою сторінкою replay
- `expect no gaps` означає, що між попереднім recovery/snapshot boundary і поточним result немає втраченої ділянки історії
- `expect no duplicate side effects` означає, що повторна доставка вже отриманого event/message не змінює state повторно
- `expect message deleted` означає, що final state message є deleted
- `expect not message body "<text>"` означає, що цей body більше не спостерігається у final state message
- `expect bob in roster` означає, що bob присутній у поточному roster view
- `expect bob not in roster` означає, що bob відсутній у поточному roster view
- `expect roster` означає, що result містить roster view
- `expect feeds` означає, що result містить список feed
- `expect previews` означає, що result містить preview дані для feed
- `expect not duplicate feeds` означає, що paged home result не містить feed, уже повернутих попередньою сторінкою того самого home query
- `expect shared snapshot` означає, що result містить один snapshot anchor для всього home result
- `expect unread` означає, що home/feed result містить unread view state
- `expect mentions` означає, що home/feed result містить mention-derived view state
- `expect group <name> exists` означає, що group/conference ресурс існує
- `expect <user> is owner of group <name>` означає, що user має owner role у вказаній group
- `expect <user> is member of group <name>` означає, що user є member вказаної group
- `expect groups` означає, що result містить список group/conference ресурсів
- `expect members` означає, що result містить список member для поточної group
- `expect <name> in groups` означає, що group <name> присутня у поточному group list result
- `expect moderation` означає, що result містить moderation list
- `expect <user> is banned` означає, що для поточного actor існує moderation restriction щодо цього user
- `expect <user> in moderation` означає, що user присутній у поточному moderation list result
- `expect <user> is banned in group <name>` означає, що існує group-scoped moderation restriction для цього user у вказаній group
- `expect subscriptions` означає, що result містить список subscription relation
- `expect <user> in subscriptions` означає, що user присутній у поточному subscription list result
- `expect subscription to <user>` означає, що directed relation до цього user існує для поточного actor
- `expect result items` означає, що result містить список елементів (items)
- `expect messages` означає, що result містить повідомлення (message items)
- `expect events` означає, що result містить event items
- `expect event <...>` означає exact match для protocol-level event
- для presence на цьому етапі мінімально зафіксована runtime form:
  - `disconnect` -> `expect event offline ...`
- `expect event offline` допускає wildcard actor
- `expect event offline <user>` вимагає exact actor match
- explicit exact form теж валідна:
  - `expect event presence offline ...`
- `connect` / `reconnect` після fully-offline state може спостерігатись як:
  - `expect event online <user>`
- explicit exact form теж валідна:
  - `expect event presence online ...`
- `expect event message read ...` використовує DSL форму `up to <seq>` замість protocol-level `readSeq`
- `expect next` означає, що result містить continuation cursor (`next`)
- `expect not next` означає, що continuation cursor (`next`) відсутній у result
- `expect result items <= N` означає, що кількість items не перевищує N
- `expect result items = 0` означає, що result не містить items
- `expect feeds count <= N` означає, що кількість feed у result не перевищує N
- `expect events count <= N` означає, що кількість events не перевищує N

Argument rules застосовуються до обох рівнів DSL (canonical і exact).

### ABAC / Access Policy extension

DSL допускає розширення для опису access policy (ABAC),
яке працює поверх protocol model.

ABAC у DSL:

- не змінює Message/Event/Query semantics
- не впливає на replay, ordering або read cursor
- визначає лише доступ до дій і view

---

### ABAC DSL surface (minimal)

На цьому етапі DSL підтримує мінімальний набір форм
для policy-сценаріїв:

#### Subject attributes

```
given alice has clearance secret
given alice has branch civil
given alice has org acme
```

#### Resource attributes

```
given message has classification confidential
given message m1 has classification secret
given feed room1 has branch military
```

#### Policy actions

```
when alice sends message
when alice queries inbox
when alice queries events for group room1
```

#### Policy expectations

```
expect access allowed
expect access denied

expect message m1 visible
expect message m2 hidden

expect message m1 field body visible
expect message m1 field attachment hidden
```
---

### Relation to schema

ABAC DSL є sugar над schema-level моделлю
(Person / Employee / Authority / resource / context).

DSL не вводить власну модель атрибутів,
а лише надає читабельну форму для сценаріїв.

---

### Scope

ABAC DSL використовується виключно для:

- command authorization
- query authorization
- view filtering

ABAC DSL не є повною policy language
і не фіксує спосіб реалізації policy engine.

## Duality

| Canonical                                   | Exact                                                       |
|---------------------------------------------|-------------------------------------------------------------|
| auth                                        | authority authenticate request                              |
| auth resume                                 | authority authenticate request with session/accessToken     |
| renew                                       | authority renew request with refreshToken                   |
| add bob to roster                           | query subscription create target bob                        |
| remove bob from roster                      | query subscription remove target bob                        |
| query roster                                | query roster list                                           |
| bootstrap home                              | query home                                                  |
| bootstrap home limit 20                     | query home limit 20                                         |
| bootstrap home limit 20 preview 1           | query home limit 20 preview 1                               |
| query home continue                         | query home continue                                         |
| expect feeds                                | expect result contains feeds                                |
| expect previews                             | expect result contains previews                             |
| expect shared snapshot                      | expect result contains shared snapshot anchor               |
| expect unread                               | expect result contains unread view state                    |
| expect bob in roster                        | expect roster contains bob                                  |
| expect bob not in roster                    | expect roster does not contain bob                          |
| expect message from alice "hi"              | expect inbound message from alice body "hi"                 |
| send read for last                          | query cursor read feed private:alice up to 123              |
| send read peer alice for last               | query cursor read feed private:alice up to 123              |
| send read group room1 for last              | query cursor read feed group:room1 up to 123                |
| expect more                                 | expect hasMore true                                         |
| query inbox continue                        | query inbox feed private:alice continue                     |
| query events peer bob after cursor          | query events feed private:bob after cursor                  |
| query inbox peer bob                        | query inbox feed private:bob                                |
| query cursor read peer alice up to 123      | query cursor read feed private:alice up to 123              |
| query inbox group room1                     | query inbox feed group:room1                                |
| query events group room1 after snapshot     | query events feed group:room1 after snapshot                |
| expect events non-empty                     | expect events count > 0                                     |
| expect event message read bob up to 12      | expect message event type read actor bob seq 12             |
| expect event message deleted alice id m1id  | expect message event type deleted actor alice id m1id       |
| expect event presence offline bob           | expect presence event type offline actor bob                |
| expect empty replay                         | expect events = 0                                           |
| expect no duplicates                        | expect result has no duplicate items/events                 |
| expect no gaps                              | expect result covers boundary without missing items/events  |
| send message to bob "hi" capture id as m1id | send message to bob; bind returned message identity as m1id |
| edit message ref "m1" body "m1 edited"      | apply message mutation by scenario-local reference          |
| edit message id m1id body "m1 edited"       | apply message mutation by captured protocol identity        |
| delete message ref "m1"                     | apply message delete by scenario-local reference            |
| delete message id m1id                      | apply message delete by captured protocol identity          |
| expect message deleted                      | expect final message state = deleted                        |
| create group room1                          | query conference create name room1 type group               |
| delete group room1                          | query conference remove name room1                          |
| add bob to group room1                      | query member add actor bob feed group:room1                 |
| remove bob from group room1                 | query member remove actor bob feed group:room1              |
| expect group room1 exists                   | expect conference room1 exists                              |
| expect alice is owner of group room1        | expect member alice role owner feed group:room1             |
| expect alice is member of group room1       | expect member alice role member-or-owner feed group:room1   |
| expect bob is member of group room1         | expect member bob role member-or-owner feed group:room1     |
| query group room1                           | query conference get name room1                             |
| query groups                                | query conference list type group                            |
| query members of group room1                | query member list feed group:room1                          |
| expect groups                               | expect result contains groups                               |
| expect members                              | expect result contains members                              |
| expect room1 in groups                      | expect groups contain room1                                 |
| ban bob                                     | query moderation ban target bob                             |
| unban bob                                   | query moderation unban target bob                           |
| query moderation                            | query moderation list                                       |
| expect moderation                           | expect result contains moderation items                     |
| expect bob is banned                        | expect moderation contains bob                              |
| expect bob in moderation                    | expect moderation contains bob                              |
| query subscription bob                      | query subscription get target bob                           |
| query subscriptions                         | query subscription list                                     |
| expect subscriptions                        | expect result contains subscriptions                        |
| expect bob in subscriptions                 | expect subscriptions contain bob                            |
| expect subscription to bob                  | expect subscription target bob exists                       |
| expect event offline bob                    | expect event presence offline bob                           |
| expect event online bob                     | expect event presence online bob                            |

Canonical = sugar  
Exact = protocol-observable semantics

Для event expect form exact side у цій таблиці означає
protocol-observable event matching semantics,
а не остаточно зафіксований wire syntax конкретного Event packet.

Для message mutation exact side у цій таблиці означає
protocol-observable addressing semantics, а не остаточно зафіксований wire syntax.

Тобто duality тут фіксує:
- який identity/addressing mode використовується;
- що саме спостерігається на protocol level;
- але не нав'язує остаточну ASN.1 форму mutation command/event.

Structured message form є розширенням canonical DSL,
а не заміною short form.

Наприклад:

```text
send message to bob "hi"
send message to bob {
  body: "hi"
  subject: "Draft"
}
```

Обидві форми можуть співіснувати, але short form лишається
основною canonical формою для простих message сценаріїв.

### Read duality

Simple:

```
send read for last
send read peer alice for last
send read group room1 for last
```

Exact:

```
query cursor read feed private:alice up to 123
query cursor read feed group:room1 up to 123
```

`send read ...` у canonical є sugar над `query cursor read ...` у exact формі.
У точній формі read повинен явно визначати:
- feed
- upper read boundary (`up to <seq>`)

Числовий read cursor update у DSL допускається тільки в exact формі.

---

#### Read semantics

`send read for last` означає оновлення read cursor до останнього
локально спостереженого seq у цій session.
- read не означає, що клієнт бачив весь feed
- read може виконуватись після partial replay або preview
- read є cursor-based і не залежить від повноти історії
- якщо потрібна явна read boundary, використовується exact форма `query cursor read ... up to <seq>`

#### Auth semantics

`auth` у canonical DSL означає первинну аутентифікацію або відновлення session,
залежно від наявного auth context.

- `auth` без додаткового context означає первинну аутентифікацію
- `auth resume` означає спробу відновити існуючу session
- `renew` означає перевидачу access token через refresh token
- exact форма використовується там, де потрібно явно вказати token/session fields

#### Subscription semantics

- subscription є directed relation state:
  - actor -> target

- `query subscription <user>` означає inspection directed relation
  від поточного actor до цього user

- `query subscriptions` означає list directed relation
  для поточного actor

- subscription є джерелом істини для relation state,
  тоді як roster є snapshot/view цього state

- subscription inspection не означає messaging authorization policy саме по собі,
  якщо окрема server policy не визначає інше

#### Roster semantics

Canonical roster DSL розділяє mutation і view:

- `add <user> to roster`
  означає створення directed relation для поточного actor
  і в exact формі зводиться до:
  `query subscription create target <user>`

- `remove <user> from roster`
  означає видалення directed relation для поточного actor
  і в exact формі зводиться до:
  `query subscription remove target <user>`

- `query roster`
  означає запит roster view
  і в exact формі зводиться до:
  `query roster list`

Таким чином:
- relation state змінюється через `Subscription`
- roster перевіряється через `Roster` як snapshot/view

`add <user> to roster` означає додавання directed roster-visible relation
для поточного користувача.

`remove <user> from roster` означає видалення directed roster-visible relation
для поточного користувача.

`query roster` означає запит поточного roster view користувача.

У private feed query canonical alias завжди означає peer.
Тобто назва private feed у DSL є user-facing назвою діалогу з іншим учасником,
а не self-ідентифікатором поточної session.

- roster у DSL трактується як view, а не як джерело істини для messaging authorization
- add/remove у roster не означає автоматичний дозвіл або заборону direct messaging
- relation може бути one-way або mutual
- direct messaging у базовій моделі не залежить від наявності roster entry
- relation-gated messaging може бути додана окремою policy, але не є частиною базової DSL semantics

#### Group semantics

- `create group <name>` створює conference ресурс типу group
- owner у group semantics також має member access до group feed
- creator автоматично стає owner і member
- `add <user> to group <name>` додає member relation
- `remove <user> from group <name>` видаляє member relation

Canonical group reference:
- `group <name>`

Exact group reference:
- `feed group:<name>`

`group <name>` у canonical DSL є typed reference на group feed/resource.
`feed group:<name>` у exact DSL є explicit protocol-level form того самого ресурсу.
Для group-related expect canonical DSL теж використовує explicit group reference:

- `expect alice is owner of group room1`
- `expect bob is member of group room1`

Implicit group context для owner/member expect не використовується.

- тільки member може:
  - `send message to group:<name>`
  - `query inbox group <name>`
  - `query events group <name> after ...`

`send message to group:<name>` лишається canonical target form для message command.
Reference kinds (`group <name>` / `feed group:<name>`) використовуються для inbox/events/read query.

- exact форма для цих самих операцій:
  - `query inbox feed group:<name>`
  - `query events feed group:<name> after ...`

- non-member отримує:
  - error forbidden

- якщо group видалена:
  - доступ до group feed → error notFound
- `query group <name>` означає inspection конкретної conference/group
- `query groups` означає list group/conference ресурсів
- `query members of group <name>` означає inspection membership для цієї group

#### Moderation semantics

- moderation є окремою policy layer
- moderation не є roster
- moderation не є subscription

- `ban <user>` створює moderation restriction для поточного actor
- `unban <user>` видаляє moderation restriction для поточного actor
- `query moderation` означає inspection поточного moderation list
- group-scoped runtime moderation може задаватись окремою form:
  - `ban <user> in group <name>`
  - `unban <user> in group <name>`
  - `query moderation group <name>`

- ці forms означають moderation state лише для цього group resource
  і не означають global moderation state

- `expect <user> is banned in group <name>`
  означає group-scoped moderation restriction для цього group
- moderation може обмежувати direct messaging або інший доступ,
  але не повинна неявно змінювати roster чи subscription state,
  якщо це окремо не визначено policy сервером

- у базовій DSL semantics ban інтерпретується як policy,
  яка блокує direct messaging від banned user
- якщо resource scope не вказаний явно, moderation трактується як subject-scoped / global policy flag

- canonical form:
  - `ban <user>`
  - `given <user> is banned`

  означає global moderation state без прив'язки до конкретного group/feed

- group-scoped moderation, якщо буде потрібна, повинна задаватись явно окремою form,
  наприклад:
  - `given <user> is banned in group <name>`

- implicit "current group" для moderation не використовується
- `given <user> is banned in group <name>` означає moderation restriction
  лише для цього group resource і не означає global ban

- group-scoped moderation не видаляє membership автоматично,
  якщо це окремо не визначено policy

- `given <user> is banned`
  і `given <user> is banned in group <name>`
  є різними state forms:
  - перше = global / subject-scoped moderation
  - друге = resource-scoped moderation

- аналогічна різниця діє і для runtime commands:
  - `ban <user>` / `unban <user>` = global moderation
  - `ban <user> in group <name>` / `unban <user> in group <name>` = group-scoped moderation

## Given section

DSL може містити опціональну секцію `given`, яка описує початковий стан сценарію.

`given` розташовується одразу після `scenario`
і перед будь-якими runtime командами (`session`, `send`, `query`, `expect`).

### Semantics

`given` описує тільки state, а не дії.

- `given` не означає історію подій
- `given` не виконує protocol commands
- `given` не генерує events/message delivery
- `given` не проходить через auth/permission checks
- `given` напряму задає world state

`given` використовує exact / protocol-level addressing model.

Тобто в `given` допустимі explicit state references на кшталт:

- `private feed alice<->bob`
- `group feed room1`
- `bob read private:alice up to 3`
- `bob read group:room1 up to 5`

Це не canonical user-facing DSL, а опис точного seeded state.

Натомість runtime сценарії за замовчуванням використовують canonical DSL:

- `query events peer alice after cursor`
- `query inbox group room1`
- `send read for last`

Таким чином:

- `given` фіксує exact state
- runtime DSL описує дії та observable behavior

`given` є implementation-independent:
- він не прив’язаний до БД
- він не залежить від конкретної серверної логіки
- canonical форма повинна зводитись до exact state assertions

---

### Supported state

`given` може описувати:

- існування ресурсів
- membership / roles
- relation (subscription / roster)
- moderation state
- feed contents
- read cursor

---

### Canonical examples

```
scenario example

given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1

  alice has bob in roster
  bob is banned by alice

  private feed alice<->bob has messages
    1 from alice "m1"
    2 from bob "m2"

  bob read private:alice up to 2
```

---

### Feed contents

Canonical:

```
given
  private feed alice<->bob has messages
    "m1"
    "m2"
```

Exact form with explicit identity:

```
given
  private feed alice<->bob has messages
    1 id "msg-123" as m1id from alice "m1"
    2 id "msg-124" from bob "m2"
```

Тут:
- id "..." задає protocol-level message identity у seeded state
- as <alias> створює DSL alias для цього exact id
- цей alias може далі використовуватись у runtime mutation form:
  - edit message id m1id ...
  - delete message id m1id

Structured form:

```
given
  private feed alice<->bob has messages
    1 from alice {
      body: "m1"
      subject: "Draft"
      priority: high
    }
```

Правила:

- порядок визначає `seq`, якщо він не заданий явно
- рекомендується використовувати explicit форму (`seq + sender`)
  для уникнення неявних припущень
- structured given payload використовує ту саму flat field model, що і `send message`
- `body` є обов'язковим полем
- `body` повинен бути string
- duplicate fields -> `error badRequest`
- nested objects і arrays у given payload не підтримуються
- explicit identity може бути задана через id "..." у message entry
- optional as <alias> створює DSL alias для seeded protocol identity
- seeded id і runtime capture id as є різними способами отримати той самий addressing mode для edit/delete message id ...
- given не виконує capture; він напряму задає exact state, включно з message identity
- якщо explicit id повторюється в межах одного seeded world state, це є невалідним given state

Structured given payload:
- задає payload повідомлення у feed log
- не генерує delivery або events
- не означає inbox state
- є лише описом initial state

TODO:
- exact mapping між canonical capture-id flow і protocol-level exact form
- exact mapping між canonical payload/mutation form і protocol-level exact form

---

### Group / membership

```
given
  group room1 exists
  alice is owner of group room1
  bob is member of group room1
```

---

### Roster / relation

```
given
  alice has bob in roster
```

`given` описує relation state, а не операцію.

---

### Moderation

```
given
  bob is banned by alice
```

Це state, а не команда `ban`.

---

### Read state

```
given
  bob read private:alice up to 3
  bob read group:room1 up to 5
```

- read є feed-scoped
- read задається через cursor (`seq`)
- read не означає повний replay або delivery history

---

### Normalization

Canonical `given` повинен зводитись до точного набору state assertions.

Приклад:

```
private feed alice<->bob has messages
  1 from alice "m1"
```

нормалізується у:

```
feed private:alice:bob message seq 1 from alice body "m1"
```

---

### Private feed identity

```
private feed alice<->bob
```

інтерпретується як:

```
feed private:alice:bob
```

- порядок alias не має значення
- `alice<->bob` == `bob<->alice`

---

### Important constraints

#### No implicit delivery

```
given private feed alice<->bob has messages
```

- не означає, що ці повідомлення вже отримані session
- не означає inbox state
- задає тільки feed log

#### No implicit events

```
given bob read ...
```

- не генерує read events
- лише задає cursor state

#### No authorization checks

```
given bob is member of group room1
```

- не виконує `add member`
- не перевіряє permissions
- просто задає state

---

### Execution model

`given` застосовується перед початком сценарію:

1. парсинг сценарію
2. застосування `given` → world state
3. виконання runtime DSL

`given` не використовує runtime handlers (`send`, `query`, `ban`, etc.)

---

### Relation to runtime

- `given` задає initial state
- runtime DSL працює поверх цього state
- якщо `given` суперечить runtime діям —
  runtime інтерпретується як зміна цього state

---

### Migration note

`given` замінює неявний `_seed_scenario`.

- якщо `given` присутній → `_seed_scenario` не використовується
- якщо `given` відсутній → можливий fallback (legacy)

Мета — повністю прибрати hidden state setup
і зробити всі сценарії явними
