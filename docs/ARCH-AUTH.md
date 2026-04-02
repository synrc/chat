# IAM / PKI / ABAC модель (CHAT)

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

