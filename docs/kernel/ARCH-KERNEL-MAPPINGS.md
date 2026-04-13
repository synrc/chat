# ARCH-KERNEL-MAPPINGS

Коротка карта системи поверх `DSL-SEMANTIC-KERNEL.md` і `DSL-TYPED-KERNEL-REFINEMENT.md`.
Мета цього документа: показати, з чого складається kernel, що є "іменниками", що є "дієсловами", і як surface DSL зводиться до kernel-форм.

## 1. Онтологія

### Ресурси

- `Principal` — actor / user identity
- `Session` — session-scoped identity
- `Feed` — канал взаємодії (`Private`, `Group`, `Token`)
- `Message` — адресований message resource
- `Group` — group resource

### Події

- `Event` — те, що відбулося в runtime (`Received`, `Delivered`, `Read`, `Edited`, `Deleted`, `UserPresence`, `SessionPresence`)

### Спостереження

- `Observation` — те, що сценарій може спостерігати (`MessageObs`, `EventObs`, `ViewObs`)

### Твердження

- `Predicate` — те, що сценарій перевіряє (`Holds`, `Seen`, `CountIs`, `HasMore`, `HasSnapshot`, `NoDuplicates`, `NoGaps`, `AccessIs`)

### Стан

- `State` — набір фактів системи

### Семантичні судження

- `Judgment` — форма семантики (`Steps`, `Produces`, `Satisfies`, а також well-formedness / permission judgments)

У kernel це розведено навмисно: ресурс, подія, спостереження, твердження, стан і семантичне судження не є одним і тим самим.

## 2. Дії

Kernel action layer описує canonical kernel-level дії, а не surface DSL-синтаксис:

- `SessionOp`
- `Post`
- `Mutate`
- `MarkRead`
- `Replay`
- `View`
- `ChangeRelation`
- `ChangeRole`
- `ChangeModeration`

Тобто surface-форми на кшталт `send message`, `edit message`, `query inbox` або `expect event ...` спочатку elaborates у ці канонічні форми.

## 3. Розділення шарів

`Event ≠ Action`

`Action` може породжувати `Event`, але `Event` не є `Action`.

| Layer | Meaning |
| --- | --- |
| `Action` | що виконується |
| `Event` | що відбулося |
| `Observation` | що спостерігається |
| `Predicate` | що перевіряється (`expect`) |

Одна й та сама DSL-фраза може торкатися кількох шарів:

- `send message ...` зазвичай elaborates у `Action`
- `expect event ...` перевіряє не `Action`, а `Predicate`, який обгортає `Observation`, яка обгортає `Event`

## 4. DSL -> Kernel mappings

Нижче не нові правила, а короткі приклади того, як surface DSL опускається до канонічного kernel.

### 4.1 `expect event typing bob1`

DSL:

```text
expect event typing bob1
```

Kernel:

```ocaml
Seen (
  EventObs (
    SessionPresence {
      actor =
        ExactActor {
          session = SessionId "bob1";
          principal = Principal "bob";
        };
      kind = Typing;
    }
  )
)
```

Пояснення:

- `typing` -> `Event`
- `EventObs` -> `Observation`
- `Seen` -> `Predicate`
- форма предиката тут: `Predicate(Seen(Observation(Event)))`

### 4.2 `send message to bob "hi"`

DSL:

```text
send message to bob "hi"
```

Kernel:

```ocaml
Post {
  session = SessionId "alice1";
  actor = Principal "alice";
  feed = Private (Principal "alice", Principal "bob");
  payload = {
    body = "hi";
    fields = [];
  };
}
```

Пояснення:

- surface `send message` не є kernel-конструктором
- канонічна дія для відправки повідомлення — `Post`

### 4.3 `edit message`

DSL:

```text
edit message id m1id body "v2"
```

Kernel:

```ocaml
Mutate {
  session = SessionId "alice1";
  actor = Principal "alice";
  target =
    ExistingMessage {
      feed = Private (Principal "alice", Principal "bob");
      id = MessageId "msg-123";
    };
  op =
    ReplacePayload {
      body = "v2";
      fields = [];
    };
}
```

Пояснення:

- surface reference спочатку resolve-иться
- kernel mutation працює не з alias, а з `ExistingMessage`
- канонічна дія редагування — `Mutate`

### 4.4 `read cursor`

DSL:

```text
send read peer alice for last
```

Kernel:

```ocaml
MarkRead {
  session = SessionId "bob1";
  actor = Principal "bob";
  boundary =
    ReadBoundary {
      feed = Private (Principal "bob", Principal "alice");
      up_to = Seq 123;
    };
}
```

Пояснення:

- symbolic cursor (`last`) не доходить до kernel
- kernel зберігає explicit read boundary
- канонічна дія тут — `MarkRead`

### 4.5 `query inbox`

DSL:

```text
query inbox peer bob
```

Kernel:

```ocaml
View {
  session = SessionId "alice1";
  actor = Principal "alice";
  kind = Inbox (Private (Principal "alice", Principal "bob"));
  limit = None;
  preview = None;
  page = None;
}
```

Пояснення:

- `query inbox` не є окремим kernel-типом у refined kernel
- це `View` з конкретним `view_kind = Inbox (...)`

### 4.6 `query events ... after snapshot`

DSL:

```text
query events peer bob after snapshot
```

Kernel:

```ocaml
Replay {
  session = SessionId "alice1";
  actor = Principal "alice";
  feed = Private (Principal "alice", Principal "bob");
  after = Some (AfterFeedSnapshot (FeedSnapshotId "..."));
  limit = None;
}
```

Пояснення:

- surface `snapshot` спочатку elaborates у явний kernel boundary
- у `DSL-TYPED-KERNEL-REFINEMENT.md` це розщеплено на `AfterFeedSnapshot` / `AfterHomeSnapshot`
- у `DSL-SEMANTIC-KERNEL.md` цьому відповідає більш загальна форма `AfterSnapshot`
- канонічна дія для event/history query — `Replay`

## 5. Pipeline

```text
DSL -> Kernel -> Semantics
```

- `DSL` = presentation layer: короткі команди, sugar, aliases, symbolic forms
- `Kernel` = канонічна модель: стабільні типи сутностей, дій, observation і predicate
- `Semantics` = виконання + інваріанти: `Steps`, `Produces`, `Satisfies`, permission/state rules

Окремо: alias / symbolic / short форми не існують у kernel; вони зникають на стадії elaboration.

Практично це означає:

1. DSL-поверхня зручна для людини
2. kernel є єдиною canonical intermediate model
3. семантика визначається не на surface-формах, а на kernel-конструкторах
