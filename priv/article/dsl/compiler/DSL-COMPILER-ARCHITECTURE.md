# Архітектура компілятора DSL для сценаріїв протоколу

## Мета

Цей документ описує архітектуру мови DSL, яка використовується для опису, компіляції та перевірки сценаріїв взаємодії у messaging/pub-sub системі.

DSL розглядається як frontend до формальної моделі, а не як набір ad-hoc команд.

Ключова ідея:

```text
OCaml model:
  Kernel
  Typed AST (ручне конструювання)
  Tests

Elixir compiler:
  DSL text
  -> Lexer
  -> Parser
  -> Surface AST
  -> Normalize / Desugar
  -> Compile
  -> Erlang AST
  -> BEAM
  -> Execution over Kernel
  -> Judgments / checks
```

---

## Загальний підхід

Важливо: формальна модель системи реалізується в OCaml без використання DSL-синтаксису.

Усі сценарії на цьому рівні задаються безпосередньо через типізований AST kernel-моделі.

Синтаксис DSL (lexer, parser) з’являється лише в Elixir-реалізації компілятора.

DSL не виконується напряму. Замість цього Elixir-реалізація:

1. Парсить DSL у синтаксичне дерево
2. Нормалізує surface form
3. Компілює сценарій у Erlang AST
4. Компілює Erlang AST у BEAM
5. Виконує код поверх формального kernel
6. Перевіряє результат через semantic judgments

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
- перетворення feed references
- інтерпретацію symbolic boundary (`snapshot`, `continue`)
- перевірку базової коректності

Результатом є Erlang AST — компільована програма сценарію у форматі, що напряму компілюється у BEAM.

---

## Erlang AST

Erlang AST — це представлення сценарію як програми з ефектами у форматі, що напряму відповідає BEAM execution model.

Основна ідея:

- `send` — effectful operation
- `query` — operation, що повертає результат
- `expect` — assertion
- сценарій — композиція таких операцій

У OCaml-моделі ці операції задаються безпосередньо через типізований AST, без використання текстового синтаксису DSL.

В Elixir-компіляторі вони мають бути скомпільовані не у власний IR, а в Erlang AST як цільове представлення BEAM.

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

Ця структура описує типізований AST моделі; у цільовій Elixir-реалізації сценарій має компілюватися в Erlang AST.

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

## Execution over Kernel

Execution layer виконує скомпільований Erlang AST поверх kernel.

Він:

- застосовує action до state
- генерує observation
- перевіряє predicate
- оновлює execution state

Сигнатура виглядає приблизно так:

```text
run : program -> state -> result
```

Execution over Kernel є точкою, де Erlang AST зв’язується з формальною моделлю та runtime semantics.

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
- erlang_ast.ml

### Semantic core

- kernel.ml
- execution.ml
- judgment.ml
- typecheck.ml
- world_check.ml

### Utility

- error.ml

---

## Підсумок

Архітектура розділяє:

- синтаксис DSL (тільки в Elixir)
- типізований AST моделі (в OCaml)
- цільове Erlang AST (для BEAM)
- семантику (Kernel)
- виконання (Execution over Kernel)
- перевірку (Judgments)

Це дозволяє:

- уникнути ad-hoc логіки
- забезпечити строгість
- зробити систему розширюваною
- виконувати формальну верифікацію сценаріїв

Ключова формула:

```text
OCaml model = kernel + typed AST + tests
Elixir compiler = syntax + compile to Erlang AST
Erlang AST = compiled scenario program
Kernel = canonical semantic model
Execution over Kernel = semantics
Judgments = verification layer
```



Розділення відповідальностей:

- OCaml модель:
  - Kernel
  - Типізований AST
  - Формальні перевірки
  - Без DSL-синтаксису

- Elixir компілятор:
  - DSL синтаксис
  - Парсер і токенайзер
  - Компіляція у Erlang AST
  - Генерація BEAM коду
