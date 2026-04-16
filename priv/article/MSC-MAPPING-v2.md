# MSC-MAPPING-v2.md

## 1. Мета

Цей документ задає канонічні правила портування DSL-сценаріїв у MSC (Z.120) подання.
Він призначений як source of truth для агентів, редакторів і напівавтоматичного перенесення сценаріїв.

Документ не є повною специфікацією мови.
Його роль — зафіксувати стабільну відповідність між:
- DSL конструкціями;
- MSC core поданням;
- extension predicates, які потрібні там, де стандартної MSC форми недостатньо.

---

## 2. Базові принципи портування

### 2.1. Загальне правило

Кожен DSL-сценарій при портуванні подається у трьох шарах:

1. **DSL source**
    - оригінальний сценарій у DSL.

2. **MSC core**
    - те, що можна виразити стандартними конструкціями MSC (instances, messages, conditions, loop, alt, opt).

3. **Extensions used**
    - перелік predicates / annotations, які не належать до стандартного MSC core, але потрібні для збереження семантики.

### 2.2. Що не можна робити

Під час портування заборонено:

- змінювати семантику DSL;
- перетворювати `expect` на action;
- розкладати `given` у message flow;
- приховувати нестачу MSC core замість явного extension predicate;
- вигадувати нові predicates без явної позначки, що це extension.

### 2.3. Що потрібно робити

Під час портування потрібно:

- максимально використовувати стандартні MSC конструкції;
- все, що не виражається MSC core, оформлювати як extension;
- зберігати розділення між:
    - action,
    - observation,
    - predicate,
    - final-state checks.

---

## 3. Канонічні правила відповідності

### 3.1. Сценарій та instance-и

| DSL | MSC core | Extension | Примітка |
|---|---|---:|---|
| `scenario SimpleFlow` | `msc SimpleFlow; ... endmsc;` | ні | Назва сценарію стає назвою MSC фрагмента |
| `session alice` | `instance Alice;` | ні | Session alias → MSC instance |
| `session bob1 as bob` | `instance Bob1;` | можливо | User-scoped semantics може вимагати textual note |

### 3.2. Початковий стан

| DSL | MSC core | Extension | Примітка |
|---|---|---:|---|
| `given ...` | `Preconditions:` block | так | Окремий textual state block |
| `group room1 exists` | precondition | так | Resource existence |
| `alice is owner of group room1` | precondition | так | Membership / role state |
| `private feed alice<->bob has messages ...` | precondition | так | Initial log state |
| `bob read private:alice up to 3` | precondition | так | Seeded cursor state |

### 3.3. Дії

| DSL | MSC core | Extension | Примітка |
|---|---|---:|---|
| `connect` | `Alice -> Server : Connect()` | ні | Якщо модель включає server boundary |
| `auth` | `Alice -> Server : Authenticate(...)` | ні | Результат фіксується окремо |
| `renew` | `Alice -> Server : Renew(...)` | ні | Те саме |
| `send message to bob "hi"` | `Alice -> Server : SendMessage("hi")` + `Server -> Bob : DeliverMessage("hi")` | ні | Канонічна server-mediated форма |
| `send message to group:room1 ...` | `Alice -> Server : SendGroupMessage(...)` + delivery fanout | ні | Багато адресатів |
| `edit message ...` | `Alice -> Server : EditMessage(...)` | ні | Наслідки через event / final-state |
| `delete message ...` | `Alice -> Server : DeleteMessage(...)` | ні | Те саме |

### 3.4. Запити

| DSL | MSC core | Extension | Примітка |
|---|---|---:|---|
| `query inbox peer bob` | `Alice -> Server : InboxQuery(peer=bob)` | ні | View query |
| `query events peer bob after cursor` | `Alice -> Server : EventQuery(after=cursor)` | ні | Replay query |
| `query home` | `Alice -> Server : HomeQuery(...)` | ні | Composite bootstrap view |
| `query roster` | `Alice -> Server : RosterQuery()` | ні | Contact view |
| `query groups` | `Alice -> Server : GroupListQuery()` | ні | Group list |
| `query members of group room1` | `Alice -> Server : MemberListQuery(room1)` | ні | Membership view |
| `query moderation` | `Alice -> Server : ModerationListQuery()` | ні | Moderation view |
| `query search ...` | `Alice -> Server : SearchQuery(...)` | частково | Search-specific semantics через predicates |
| `query discover ...` | `Alice -> Server : DiscoveryQuery(...)` | частково | Feature/result predicates через extension |

---

## 4. Expect: три класи перевірок

### 4.1. Result expectations

Ці expect-и перевіряють результат команди або запиту:

- `expect authenticated`
- `expect session created`
- `expect access token`
- `expect more`
- `expect snapshot`
- `expect next`
- `expect error unauthorized`

MSC форма:
- `condition Authenticated(...)`
- `condition SessionCreated(...)`
- `condition HasMore`
- `condition HasSnapshot`
- `condition Error(unauthorized)`

### 4.2. Observation expectations

Ці expect-и перевіряють повідомлення або події, які стали спостережуваними:

- `expect message from alice body "hi"`
- `expect event offline bob`
- `expect event typing bob`
- `expect event message read bob up to 12`

MSC форма:
- `condition Seen(...)`

### 4.3. Semantic / global expectations

Ці expect-и не зводяться до одного повідомлення або події, а перевіряють властивість результату або фінального стану:

- `expect no gaps`
- `expect no duplicates`
- `expect empty replay`
- `expect message deleted`
- `expect message m1 visible`
- `expect access denied`

MSC форма:
- extension predicate у `condition`

---

## 5. Каталог extension predicates

Нижче зафіксовано мінімальний набір predicates, який дозволяє зберегти семантику DSL поверх MSC core.

### 5.1. Observation predicates

- `Seen(x)`
    - означає, що observation `x` присутнє у відповідному observation channel.

### 5.2. Replay predicates

- `NoGaps`
    - означає, що між boundary і поточним результатом немає втраченої ділянки історії.

- `NoDuplicates`
    - означає, що в результаті немає повторного покриття вже відомих items/events.

- `ReplayEmpty`
    - означає, що replay result не містить подій.

- `HasMore`
    - означає, що є продовження сторінки або replay chain.

- `HasNext`
    - означає, що result містить continuation cursor.

### 5.3. Result predicates

- `Authenticated(actor)`
    - успішна автентифікація.

- `SessionCreated(x)`
    - створено нову session.

- `AccessTokenIssued(actor)`
    - видано access token.

- `Error(code)`
    - результат завершився помилкою з кодом `code`.

### 5.4. Final-state predicates

- `FinalState(target, state)`
    - фінальний стан об’єкта `target` дорівнює `state`.

- `NotVisibleBody(text)`
    - body `text` більше не спостерігається як видимий у final state.

### 5.5. Visibility / policy predicates

- `Visible(x)`
    - observation або object `x` є видимим.

- `Hidden(x)`
    - observation або object `x` приховано.

- `FieldVisible(x, field)`
    - поле `field` visible у `x`.

- `FieldHidden(x, field)`
    - поле `field` hidden у `x`.

- `Permitted(action)`
    - дія дозволена.

- `Forbidden(action)`
    - дія заборонена.

### 5.6. Discovery / search predicates

- `HasFeature(id)`
    - feature `id` присутній у discovery result.

- `SearchShows(x)`
    - search result містить `x`.

- `SearchHides(x)`
    - search result не показує `x`.

- `ProjectionPreserved`
    - проєкція search result зберігає очікувану форму та межі.

---

## 6. Канонічні шаблони

### 6.1. Message delivery

**DSL**

```text
session alice
session bob

alice send message to bob "hi"
bob expect message from alice body "hi"
```

**MSC core**

```text
msc MessageDelivery;

  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : SendMessage("hi");
  Server -> Bob   : DeliverMessage("hi");

  condition Seen(Message(from=Alice, body="hi"));

endmsc;
```

**Extensions used**
- `Seen`

---

### 6.2. Authentication

**DSL**

```text
session alice
connect
auth
expect authenticated
```

**MSC core**

```text
msc Authenticate;

  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  condition Authenticated(Alice);

endmsc;
```

**Extensions used**
- `Authenticated`

---

### 6.3. Replay with boundary

**DSL**

```text
query events peer bob after snapshot
expect no gaps
expect no duplicates
```

**MSC core**

```text
msc ReplayAfterSnapshot;

  instance Alice;
  instance Server;

  Alice -> Server : EventQuery(after=snapshot);

  loop replay_events
    Server -> Alice : Event(...);
  endloop;

  condition NoGaps;
  condition NoDuplicates;

endmsc;
```

**Extensions used**
- `NoGaps`
- `NoDuplicates`

---

### 6.4. Read update

**DSL**

```text
send read peer alice for last
expect event message read bob up to 12
```

**MSC core**

```text
msc ReadUpdate;

  instance Bob;
  instance Server;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=12);

  condition Seen(MessageEvent(read, actor=Bob, seq=12));

endmsc;
```

**Extensions used**
- `Seen`

---

### 6.5. Visibility

**DSL**

```text
expect message m1 visible
expect message m2 hidden
```

**MSC core**

```text
msc VisibilityCheck;

  condition Visible(m1);
  condition Hidden(m2);

endmsc;
```

**Extensions used**
- `Visible`
- `Hidden`

---

### 6.6. Discovery

**DSL**

```text
query discover protocol
expect feature protocol.version
```

**MSC core**

```text
msc DiscoveryProtocol;

  instance Client;
  instance Server;

  Client -> Server : DiscoveryQuery(protocol);

  condition HasFeature(protocol.version);

endmsc;
```

**Extensions used**
- `HasFeature`

---

## 7. Правила для Codex

### 7.1. Загальні інструкції

Codex повинен:

- трактувати цей документ як канонічну mapping specification;
- не змінювати семантику сценаріїв;
- не намагатися спростити DSL шляхом втрати semantic detail;
- явно позначати всі місця, де використано extension predicate.

### 7.2. Формат виходу

Для кожного портованого сценарію Codex повинен давати:

1. назву сценарію;
2. DSL source;
3. MSC core representation;
4. Extensions used;
5. Notes (за потреби).

### 7.3. Якщо MSC core недостатньо

Якщо стандартного MSC core недостатньо, Codex повинен:

- залишити MSC core частину максимально стандартною;
- додати потрібний extension predicate;
- явно пояснити, чому він потрібен;
- не маскувати extension як нібито стандартну MSC конструкцію.

### 7.4. Given

`Given` завжди портується у блок `Preconditions`, а не в message flow.

### 7.5. Expect

`Expect` завжди мапиться в `condition`, а не в message/action flow.

### 7.6. Final state

Перевірки типу:
- deleted,
- hidden,
- final payload,
- no duplicates,
- no gaps

не повинні насильно зводитись до “ще однієї message event”,
якщо їхня семантика є state-level або result-level.

---

## 8. Порядок масового портування

Рекомендований порядок:

1. затвердити цей mapping document;
2. затвердити каталог extension predicates;
3. вибрати 8–10 еталонних сценаріїв;
4. узгодити стиль textual MSC representation;
5. портувати решту сценаріїв через шаблони, а не з нуля.

---

## 9. Висновок

DSL сценарії слід розглядати як executable MSC з extension predicates.
MSC core використовується максимально, а все, що не виражається стандартними засобами Z.120, повинно бути явно оформлено як розширення.
