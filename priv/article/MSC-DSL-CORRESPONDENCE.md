# MSC-DSL-CORRESPONDENCE

Практичний довідник стабільних відповідностей DSL → MSC.

Цей файл не дублює [MSC-MAPPING-v2.md](./MSC-MAPPING-v2.md), а фіксує:
- сталі DSL → MSC відповідності;
- канонічні правила оформлення;
- фактично використані predicates;
- короткі шаблони для типових сценаріїв.

Підтримка актуальності:
- якщо з’являється новий DSL pattern, його треба додати у таблицю;
- якщо використано новий predicate, його треба додати у список;
- якщо з’являється новий стабільний сценарій, його треба додати як шаблон;
- існуючі rules не змінюються без явної потреби.

## 1. Стабільні відповідності DSL → MSC

| DSL pattern | MSC form | Notes |
|---|---|---|
| `scenario name` | `msc Name; ... endmsc;` | Назва сценарію нормалізується до MSC fragment name |
| `session alice` | `instance Alice;` | Session alias стає instance |
| `session bob1 as bob` | `instance Bob1;` | User-scoped semantics лишається в Notes, якщо це важливо |
| `given ...` | `Preconditions:` block | Не перетворювати у message flow |
| `connect` | `Alice -> Server : Connect()` | Якщо є explicit server boundary |
| `connect alice@example.com` | `Alice -> Server : Connect(alice@example.com)` | Конкретний transport/login payload лишається в label |
| `auth` | `Alice -> Server : Authenticate(...)` | Деталі auth лишаються в параметрах |
| `auth password "secret"` | `Alice -> Server : Authenticate(password="secret")` | Канонічно як explicit auth payload |
| `auth resume` | `Alice -> Server : Authenticate(resume)` | Resume оформлюється як auth variant |
| `disconnect` | `Alice -> Server : Disconnect()` | Session-level дія |
| `reconnect` | `Alice -> Server : Connect()` | Окреме повторне підключення |
| `send message to bob "hi"` | `Alice -> Server : SendMessage("hi")` + `Server -> Bob : DeliverMessage("hi")` | Канонічна server-mediated delivery |
| `send message to bob { ... }` | `Alice -> Server : SendMessage(...)` + `Server -> Bob : DeliverMessage(...)` | Structured payload лишається в message label |
| `send message to group:room1 "g1"` | `Alice -> Server : SendGroupMessage(room1, "g1")` + delivery fanout | Для group feed |
| `create group room1` | `Alice -> Server : CreateGroup(room1)` | Resource mutation |
| `add bob to group room1` | `Alice -> Server : AddMember(room1, Bob)` | Membership mutation |
| `add bob to roster` | `Alice -> Server : AddToRoster(Bob)` | Roster relation mutation |
| `remove bob from roster` | `Alice -> Server : RemoveFromRoster(Bob)` | Roster relation mutation |
| `query roster` | `Alice -> Server : RosterQuery()` | Roster view query |
| `query inbox peer alice` | `Bob -> Server : InboxQuery(peer=alice)` | History/view query |
| `query events peer alice after cursor` | `Bob -> Server : EventQuery(peer=alice, after=cursor)` | Канонічний replay query |
| `query events peer alice after cursor limit 2` | `Bob -> Server : EventQuery(peer=alice, after=cursor, limit=2)` | Bounded replay |
| `query cursor read feed private:alice up to 2` | `Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2)` | Read cursor treated as command/update |
| `send read for last` | `Bob -> Server : UpdateReadCursor(feed=..., up_to=last_observed)` | Конкретне `up_to` виводиться з локально observed boundary |
| `send read group room1 for last` | `Bob -> Server : UpdateReadCursor(feed=group:room1, up_to=last_observed)` | Feed-scoped read update |
| `expect message from alice body "hi"` | `condition Seen(Message(from=Alice, body="hi"));` | Observation-level check in the receiving instance scope |
| `expect message marked as read` | `condition Seen(MessageEvent(read, actor=Bob, seq=N));` | Конкретна read observation у receiving / observing instance scope, не final-state check |
| `expect read cursor updated` | `condition FinalState(ReadCursor(...), up_to=N);` | Єдина форма для read cursor result semantics |
| `expect read cursor unchanged in private:alice` | `condition NotChanged(ReadCursor(actor=Bob, feed=private:alice));` | Для isolation / no side effect |
| `expect bob in roster` | `condition FinalState(Roster(actor=Alice), contains(Bob));` | Roster membership as actor-local final view state |
| `expect bob not in roster` | `condition FinalState(Roster(actor=Alice), excludes(Bob));` | Negative roster membership as actor-local final view state |
| `expect events` | `condition ResultNotEmpty;` | Result-level check, не observation |
| `expect events non-empty` | `condition ResultNotEmpty;` | Те саме |
| `expect events count <= N` | `condition ResultCount <= N;` | Для bounded replay/page results |
| `expect messages` | `condition ResultNotEmpty;` | Result-level перевірка для view/history result, не observation-level check |
| `expect more` | `condition HasMore;` | Pagination / replay continuation |
| `expect not more` | `condition HasMore = false;` | Негативна форма без нового predicate |
| `expect empty replay` | `condition ReplayEmpty;` | Replay result is empty |
| `expect error badRequest` | `condition Error(badRequest);` | Result error |
| `expect no gaps` | `condition NoGaps;` | Replay continuity |
| `expect no duplicates` | `condition NoDuplicates;` | Replay overlap check |

## 2. Канонічні rules

### 2.1. General

- Використовувати MSC core спочатку: `instance`, arrows, `loop`, `alt`, `opt`, `condition`.
- `given` завжди оформлюється як `Preconditions:`, а не як flow.
- `expect` ніколи не перетворюється на action.
- Якщо сценарій server-mediated, використовувати явний `instance Server`.

### 2.2. Result vs Observation

- Result-level перевірки оформлюються через `condition ResultNotEmpty`, `HasMore`, `ReplayEmpty`, `Error(...)`, `FinalState(...)`.
- Observation-level перевірки оформлюються тільки через `condition Seen(...)`.
- `Seen(...)` трактується у scope receiving / observing instance; якщо receiving side неявна, цей scope вважається implicit from scenario context.
- Не використовувати `Seen(...)` для позначення просто факту наявності result.

### 2.3. Read cursor

- `expect read cursor updated` завжди оформлюється тільки як `condition FinalState(ReadCursor(...), up_to=...)`.
- `expect message marked as read` лишається observation-level перевіркою через `Seen(MessageEvent(read, ...))`.
- Для isolation semantics використовувати `NotChanged(ReadCursor(...))`.

### 2.4. Replay and Pagination

- Для replay у read-сценаріях можна використовувати `MessageEvent(...)` усередині replay loop.
- `MessageEvent(...)` у replay template є прикладом для read-oriented scenarios, а не універсальним event type для всіх replay cases.
- Бажана назва loop: `replay_events`.
- Якщо replay/query bounded by `limit`, додавати `condition ResultCount <= N;`.
- `expect more` / `expect not more` відображаються через `HasMore` / `HasMore = false`.

### 2.5. Naming and Style

- Назви predicates мають бути однаковими по всьому корпусу.
- `FinalState(...)` має використовуватись в одній формі без варіантів на кшталт cursor-updated event predicates.
- `Roster(actor=X)` завжди означає actor-local roster view користувача `X`, а не global/shared relation object.
- `Extensions used` містить тільки реально використані predicates без дублювання.

## 3. Predicates in Use

### Observation

- `Seen(Message(...))`
- `Seen(MessageEvent(...))`

### Result / Replay

- `ResultNotEmpty`
- `ResultCount <= N`
- `HasMore`
- `ReplayEmpty`
- `Error(code)`
- `NoGaps`
- `NoDuplicates`

### Final-state / Consistency

- `FinalState(target, state)`
- `NotChanged(target)`

### Other documented predicates from mapping

- `Authenticated(actor)`
- `SessionCreated(x)`
- `AccessTokenIssued(actor)`
- `HasNext`
- `Visible(x)`
- `Hidden(x)`
- `FieldVisible(x, field)`
- `FieldHidden(x, field)`
- `Permitted(action)`
- `Forbidden(action)`
- `HasFeature(id)`
- `SearchShows(x)`
- `SearchHides(x)`
- `ProjectionPreserved`

## 4. Short Templates

### 4.1. Delivery

**DSL**

```text
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
```

**MSC**

```text
msc MessageDelivery;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("hi");
  Server -> Bob : DeliverMessage("hi");

  condition Seen(Message(from=Alice, body="hi"));
endmsc;
```

### 4.2. Read

**DSL**

```text
session bob
send read for last

expect read cursor updated
```

**MSC**

```text
msc ReadUpdate;
  instance Bob;
  instance Server;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=2);
endmsc;
```

### 4.3. Replay

**DSL**

```text
query events peer alice after cursor

expect events
```

**MSC**

```text
msc ReplayQuery;
  instance Bob;
  instance Server;

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Примітка:
- `MessageEvent(...)` тут показано як read-oriented replay example; для інших domain scenarios конкретний event type може відрізнятись.

### 4.4. Roster Membership

**DSL**

```text
session alice
connect
auth

add bob to roster

query roster

expect bob in roster
```

**MSC**

```text
msc AddToRoster;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);
  Alice -> Server : RosterQuery();

  condition FinalState(Roster(actor=Alice), contains(Bob));
endmsc;
```

Примітка:
- `Roster(actor=Alice)` означає локальний roster view Alice.

### 4.5. Pagination / Bounded Replay

**DSL**

```text
query events peer alice after cursor limit 1

expect events count <= 1
expect more
```

**MSC**

```text
msc ReplayPage;
  instance Bob;
  instance Server;

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=1);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 1;
  condition ResultNotEmpty;
  condition HasMore;
endmsc;
```
