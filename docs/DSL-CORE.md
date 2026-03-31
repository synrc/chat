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

- `cursor`
- `next`
- `snapshot`

`cursor` означає збережену replay position цієї session
- використовується для recovery після reconnect
- відповідає останньому відомому seq у feed для цієї session
- не залежить від локально отриманих подій у поточному replay
`snapshot` означає snapshot anchor, отриманий з попереднього inbox query

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

Argument rules застосовуються до обох рівнів DSL (canonical і exact).

## Duality

| Canonical                      | Exact                                                      |
|--------------------------------|------------------------------------------------------------|
| auth                           | authority authenticate request                           |
| auth resume                    | authority authenticate request with session/accessToken  |
| renew                          | authority renew request with refreshToken                |
| expect message from alice "hi" | expect inbound message from alice body "hi"                |
| send read for last             | query cursor read feed private:alice seq 123               |
| expect more                    | expect hasMore true                                        |
| query inbox continue           | query inbox feed private:alice continue                    |
| query events bob after cursor  | query events feed private:bob after cursor               |
| expect events non-empty        | expect events count > 0                                    |
| expect empty replay            | expect events = 0                                          |
| expect no duplicates           | expect result has no duplicate items/events                |
| expect no gaps                 | expect result covers boundary without missing items/events |
| send read group:room1 for last | query cursor read feed group:room1 seq 123                 |

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

