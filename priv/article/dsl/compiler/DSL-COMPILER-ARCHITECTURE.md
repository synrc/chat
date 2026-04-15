# Архітектура компілятора DSL для сценаріїв протоколу

## Мета

Цей документ описує архітектуру мови DSL, яка використовується для опису, компіляції та перевірки сценаріїв взаємодії у messaging/pub-sub системі.

DSL розглядається як frontend до формальної моделі, а не як набір ad-hoc команд.

Ключова ідея:

```text
DSL text
-> Lexer
-> Parser
-> CST
-> Surface AST
-> Normalize / Desugar
-> Compile
-> Program IR
-> Interpreter over Kernel
-> Judgments / checks
```

---

## Загальний підхід

DSL не виконується напряму. Замість цього він:

1. Парситься у синтаксичне дерево
2. Нормалізується
3. Компілюється у проміжне представлення (Program IR)
4. Інтерпретується поверх формального kernel
5. Перевіряється через систему semantic judgments

Таким чином система має чітке розділення між:

- синтаксисом
- програмою сценарію
- семантикою
- перевіркою

---

## Шари системи

### 1. Lexer

Відповідає за токенізацію вхідного тексту.

Виділяє:
- ключові слова
- ідентифікатори
- рядки
- числа
- розділювачі

Lexer не містить доменної логіки.

---

### 2. Parser

Будує Concrete Syntax Tree (CST) або близький до поверхні AST.

Parser відповідає лише за форму конструкцій, наприклад:

- session declaration
- send / query / expect
- payload
- boundary expressions

Parser не виконує semantic resolution.

---

### 3. Surface AST

Представляє DSL у вигляді, близькому до вихідного тексту.

Тут можуть бути присутні:
- syntactic sugar
- short forms
- symbolic форми (`snapshot`, `continue`, `last`)
- alias-и

Це ще не canonical представлення.

---

### 4. Normalize / Desugar

Цей шар зводить різні syntactic варіанти до єдиної форми.

Приклади:

- short message form → structured payload
- canonical expect → explicit structure
- default values для опцій

Це ще не повний semantic етап, але форма стає уніфікованою.

---

### 5. Compile (Elaboration)

Це основний semantic шар frontend-а.

Він виконує:

- resolution alias-ів
- роботу з контекстом сесії
- перетворення resource references
- інтерпретацію symbolic boundary (`snapshot`, `continue`)
- перевірку базової коректності

Результатом є **Program IR** — компільована програма сценарію.

---

## Program IR

Program IR — це проміжне представлення сценарію як програми з ефектами.

Основна ідея:

- `send` — effectful operation
- `query` — operation, що повертає результат
- `expect` — assertion
- сценарій — композиція таких операцій

### Приклад структури

```ocaml
type _ op =
  | Connect : unit op
  | Auth : unit op
  | SendMessage : {
      target : Kernel.feed;
      payload : Kernel.payload;
    } -> Kernel.message_id op
  | QueryEvents : {
      feed : Kernel.feed;
      after : Kernel.replay_boundary option;
      limit : int option;
    } -> Kernel.observation op
  | Expect : Kernel.predicate -> unit op

type _ program =
  | Return : 'a -> 'a program
  | Bind : 'b program * ('b -> 'a program) -> 'a program
  | Op : 'a op -> 'a program
```

Program IR є строго типізованим і визначає порядок виконання ефектів.

---

## Kernel

Kernel — це канонічна семантична модель системи.

Він включає:

- Action
- Event
- Observation
- Predicate
- Judgment
- типізовані reference-и (message, group, feed)
- boundaries (read, replay)
- view semantics

Kernel не містить DSL-специфічного синтаксису.

---

## Interpreter

Interpreter виконує Program IR поверх kernel.

Він:

- застосовує action до state
- генерує observation
- перевіряє predicate
- оновлює execution state

Сигнатура виглядає приблизно так:

```text
run : program -> state -> result
```

Interpreter є єдиною точкою, де відбувається execution semantics.

---

## Judgments та перевірки

Після або під час інтерпретації застосовуються перевірки:

- WellFormedAction
- WellFormedPayload
- StateHas
- Permits
- Produces
- Satisfies

Ці перевірки працюють над kernel-рівнем.

---

## Структура модулів

### Frontend

- token.ml
- lexer.ml
- parser.ml
- cst.ml
- surface_ast.ml
- normalize.ml

### Compilation

- env.ml
- compile.ml
- program.ml

### Semantic core

- kernel.ml
- interpreter.ml
- judgment.ml
- typecheck.ml
- world_check.ml

### Utility

- error.ml

---

## Підсумок

Архітектура розділяє:

- синтаксис (DSL)
- програму сценарію (Program IR)
- семантику (Kernel)
- виконання (Interpreter)
- перевірку (Judgments)

Це дозволяє:

- уникнути ad-hoc логіки
- забезпечити строгість
- зробити систему розширюваною
- виконувати формальну верифікацію сценаріїв

Ключова формула:

```text
DSL = frontend
Program IR = compiled scenario program
Kernel = canonical semantic model
Interpreter = semantics
Judgments = verification layer
```

