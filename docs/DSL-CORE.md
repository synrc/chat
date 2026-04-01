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
- canonical DSL не використовує числові seq значення для read
- числові позиції використовуються тільки в exact формі

Приклади:

- `send message to bob "hi"` — `bob` інтерпретується як target alias
- `query inbox bob` — `bob` інтерпретується як feed alias
- `query events bob after 100 limit 10` — `bob` інтерпретується як feed alias
- `send read for last` — read у дефолтному/поточному feed контексті
- `send read <feed> for last` — read у явно вказаному feed
- `add bob to roster` — додати bob у roster (створити односторонній зв’язок)
- `remove bob from roster` — видалити bob з roster (прибрати односторонній зв’язок)
- `query roster` — отримати поточний список контактів користувача


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
- список feed
- preview елементи для feed
- continuation для pagination
- snapshot anchor для подальшого replay

Home query:
- не означає `read`
- не змінює roster relation
- не змінює message state
- не змішує relation і messaging authorization
- є view ресурсом для стартового стану клієнта

Home query повертає shared snapshot anchor для всього home result.

Цей anchor може використовуватись для подальшого
`query events <feed> after snapshot`
для будь-якого feed, already covered тим самим home result.

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

При використанні в `query events <feed> after snapshot`
shared home snapshot інтерпретується як replay boundary
для цього конкретного feed у межах того самого home bootstrap context.

`next` означає continuation cursor для наступної сторінки event replay

`last` означає останній seq, локально отриманий у цій session
- `last` не означає head feed
- `last` не означає повний replay
- `last` залежить від того, який обсяг подій був отриманий (preview / partial / full)

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

Argument rules застосовуються до обох рівнів DSL (canonical і exact).

## Duality

| Canonical                      | Exact                                                      |
|--------------------------------|------------------------------------------------------------|
| auth                           | authority authenticate request                             |
| auth resume                    | authority authenticate request with session/accessToken    |
| renew                          | authority renew request with refreshToken                  |
| add bob to roster              | TODO exact roster/relation form                            |
| remove bob from roster         | TODO exact roster/relation form                            |
| query roster                   | TODO exact roster query form                               |
| bootstrap home                 | query home                                                  |
| bootstrap home limit 20        | query home limit 20                                         |
| bootstrap home limit 20 preview 1 | query home limit 20 preview 1                           |
| query home continue            | query home continue                                         |
| expect feeds                   | expect result contains feeds                                |
| expect previews                | expect result contains previews                             |
| expect shared snapshot         | expect result contains shared snapshot anchor               |
| expect bob in roster           | expect roster contains bob                                 |
| expect bob not in roster       | expect roster does not contain bob                         |
| expect message from alice "hi" | expect inbound message from alice body "hi"                |
| send read for last             | query cursor read feed private:alice seq 123               |
| expect more                    | expect hasMore true                                        |
| query inbox continue           | query inbox feed private:alice continue                    |
| query events bob after cursor  | query events feed private:bob after cursor                 |
| expect events non-empty        | expect events count > 0                                    |
| expect empty replay            | expect events = 0                                          |
| expect no duplicates           | expect result has no duplicate items/events                |
| expect no gaps                 | expect result covers boundary without missing items/events |
| send read group:room1 for last | query cursor read feed group:room1 seq 123                 |
| edit message "m1" body "m1 edited" | TODO exact mutation form                               |
| delete message "m1"                | TODO exact mutation form                               |
| expect message deleted             | expect final message state = deleted                   |

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

Числовий read cursor update у DSL допускається тільки в exact формі.

---

#### Read semantics

`send read for last` означає оновлення read cursor до останнього
локально спостереженого seq у цій session.
- read не означає, що клієнт бачив весь feed
- read може виконуватись після partial replay або preview
- read є cursor-based і не залежить від повноти історії
- якщо потрібна явна позиція seq, використовується exact форма

#### Auth semantics

`auth` у canonical DSL означає первинну аутентифікацію або відновлення session,
залежно від наявного auth context.

- `auth` без додаткового context означає первинну аутентифікацію
- `auth resume` означає спробу відновити існуючу session
- `renew` означає перевидачу access token через refresh token
- exact форма використовується там, де потрібно явно вказати token/session fields

#### Roster semantics

`add <user> to roster` означає додавання directed roster-visible relation
для поточного користувача.

`remove <user> from roster` означає видалення directed roster-visible relation
для поточного користувача.

`query roster` означає запит поточного roster view користувача.

- roster у DSL трактується як view, а не як джерело істини для messaging authorization
- add/remove у roster не означає автоматичний дозвіл або заборону direct messaging
- relation може бути one-way або mutual
- direct messaging у базовій моделі не залежить від наявності roster entry
- relation-gated messaging може бути додана окремою policy, але не є частиною базової DSL semantics

