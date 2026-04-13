# ARCH-AUTH

IAM / PKI / ABAC модель (CHAT)

## Мета

Зафіксувати архітектурну модель ідентифікації, сесій та авторизації для CHAT протоколу.

Ключовий принцип:

> IAM — це не джерело істини, а кеш авторизації поверх PKI та directory (Employee).

---

## Компоненти

### PKI (Public Key Infrastructure)

Відповідає за криптографічну ідентичність.

Дає:

- X.509 сертифікат
- serial number
- cryptographic identity

PKI є джерелом істини для identity.

---

### Directory (Employee / Person / Org)

Описує користувача як суб'єкт у системі.

Основні сутності:

- Person — фізична особа
- Employee — identity в організації
- Organization — tenant
- Branch — ієрархія підрозділів

Employee містить атрибути:

- org
- branch
- role (legacy)
- group (legacy)
- інші атрибути

Це джерело істини для атрибутів користувача.

---

### IAM (Authority layer)

У CHAT використовується спрощена форма IAM.

IAM = auth cache

Функції:

- mapping cert.serial → user (Employee)
- управління session / device
- кешування атрибутів користувача

Приклад структури:

```
Authority:
  user_id
  session_id
  device
  cert_serial
```

IAM не є джерелом істини.

---

### ABAC (Attribute-Based Access Control)

Відповідає за правила доступу.

ABAC працює поверх атрибутів користувача та контексту.

Приклад:

```
if employee.clearance >= message.level
  allow
else
  deny
```

ABAC не залежить від roles як primary моделі.

### ABAC evaluation model

ABAC у цій архітектурі не є джерелом істини для state.

ABAC відповідає не на питання "що є істинним у протоколі",
а на питання "що дозволено для цього суб'єкта в цьому контексті".

Базова форма evaluation:

```text
allow = evaluate(
  subject,
  action,
  resource,
  context
)
```

де:

- `subject` — identity + employee attributes + session/device context
- `action` — send / edit / delete / read / query / add-member / ban / ...
- `resource` — feed / message / member / roster / home / view / field
- `context` — час, tenant, federation boundary, branch, clearance, policy inputs

---

### Що є input для ABAC

ABAC використовує дані з вже існуючих шарів:

- PKI:
  - cryptographic identity
  - cert serial
  - trust chain

- Directory / Employee:
  - org
  - branch
  - clearance
  - employment attributes
  - legacy role/group, якщо ще існують

- IAM / Authority:
  - session
  - device
  - current auth context

Тобто:

- ARCH-AUTH визначає, хто є subject
- ABAC визначає, що цьому subject дозволено

---

### Schema → ABAC mapping

ABAC використовує атрибути, що визначені в schema (ERP/1 catalogs).

DSL не вводить власну модель атрибутів, а є лише читабельним представленням цих даних.

---

#### Subject (user)

Формується з:

- PKI:
    - cert_serial

- Employee:
    - org
    - branch
    - role (legacy)
    - group (legacy)
    - position
    - status
    - type

- Person:
    - cn
    - displayName
    - type

- Authority (IAM-lite):
    - session_id
    - device

---

#### Resource

Тип ресурсу залежить від дії:

- message:
    - feed
    - sender
    - payload (fields)

- feed:
    - type (private / group)
    - id (peer / group name)

- group/member:
    - org
    - branch
    - membership state

- home/view:
    - feeds
    - previews
    - derived state

---

#### Context

Контекст формується з:

- organization / tenant
- branch hierarchy
- session/device
- federation boundary (local / remote)
- policy-specific параметри (наприклад clearance, classification)

---

#### Action

Action визначається протоколом:

- send
- edit
- delete
- read (cursor update)
- query (events, home, roster, members)
- add-member / remove-member
- ban / unban

---

#### DSL representation

У DSL ці атрибути використовуються у спрощеній формі, наприклад:

```
given alice has org acme
given alice has branch security
given alice has clearance secret

when alice sends message
expect access allowed
```

Ці вирази є sugar над schema-level моделлю і повинні
однозначно мапитись на:

- Employee
- Person
- Authority
- resource/context

---

### Що саме може контролювати ABAC

ABAC може застосовуватись на кількох рівнях:

#### 1. Command authorization

- send message
- edit message
- delete message
- read / cursor update
- add / remove member
- ban / unban

#### 2. Query authorization

- query inbox
- query events
- query roster
- query members
- query moderation
- bootstrap home

#### 3. View filtering

Навіть якщо query дозволений, ABAC може обмежувати видимість:

- окремих feed
- окремих messages
- окремих payload fields
- mention / unread aggregates
- membership / moderation details

#### 4. Field-level visibility

ABAC може визначати, що actor бачить:

- весь payload
- тільки частину payload
- тільки metadata
- тільки summary / preview

---

### Чого ABAC не повинен робити

ABAC не повинен змінювати canonical protocol truth.

Зокрема ABAC не повинен:

- змінювати Message state
- змінювати Event stream
- змінювати feed ordering (`seq`)
- створювати окрему policy-specific history
- змінювати replay semantics
- змінювати read cursor як canonical truth

ABAC визначає доступ до істини, а не саму істину.

---

### ABAC як future extension

У базовому CHAT policy layer може бути мінімальним або зовнішнім.

ABAC розглядається як майбутнє розширення, яке:

- не змінює core protocol model
- використовує вже наявні identity/session/context inputs
- додає правила доступу поверх Message / Event / Query semantics

---

## Загальна схема

```
PKI (cert)
   ↓
Employee (directory)
   ↓
IAM (session + cache)
   ↓
ABAC (rules)
```

---

## Принципи

### 1. Розділення відповідальностей

- PKI — identity
- Directory — атрибути
- IAM — кеш + сесії
- ABAC — правила

---

### 2. IAM як кеш

IAM не містить бізнес-логіку.

IAM:

- не є source of truth
- не зберігає політики
- лише мапить і кешує

---

### 3. Відмова від RBAC як базової моделі

Roles та groups можуть існувати як legacy поля, але:

> основна модель — ABAC

---

### 4. Протокол не містить IAM логіки

CHAT протокол:

- не реалізує IAM
- не управляє org / users
- працює з уже визначеним identity

---

### 5. Authority як IAM-lite

У CHAT:

IAM → Authority table

Вона відповідає за:

- session
- device
- cert binding

---

## Наслідки для протоколу

### Identity

- визначається через сертифікат
- мапиться на user через Authority

---

### Session

- session ≠ connection
- session прив'язана до cert

---

### Authorization

- не частина transport layer
- не частина DSL runner
- окремий policy layer

---

### Federation and trust assumptions

У федеративному середовищі (між різними broker/domain):

- identity користувача не створюється broker-ом, а визначається через PKI
- remote broker не є джерелом істини для identity, а лише ретранслює її

Federation спирається на такі припущення:

- сертифікат (PKI) є глобальним джерелом істини для identity
- Authority є локальним кешем (session/device binding), але не визначає identity
- remote actor (наприклад alice@brokerA) повинен бути перевірений через trust model (PKI / chain / policy)

Важливо:

- routing не повинен змінювати protocol identity повідомлення
- remote broker не повинен підміняти actor або створювати новий message identity
- message/event semantics повинні залишатися інваріантними через federation boundary

Federation не змінює базову модель протоколу:

- Message, Event і Query зберігають ту саму семантику
- read/edit/delete повинні спостерігатися як ті самі runtime факти, незалежно від домену

Таким чином:

- ARCH-AUTH визначає, хто є actor і чому йому довіряють
- federation визначає, як його події маршрутизуються між domain

### DSL (майбутнє розширення)

ABAC сценарії можуть виглядати як:

```
expect access allowed
expect access denied
```

з використанням атрибутів:

```
employee.clearance
message.level
```

---

## Висновок

Модель базується на простому, але сильному принципі:

> identity, attributes та authorization — це різні шари

Це дозволяє:

- уникнути складного IAM
- зробити систему модульною
- легко розширювати під ABAC

---

## Коротко

```
PKI → identity
Employee → attributes
IAM → cache
ABAC → rules
```

Це і є базова модель системи.
