# ARCH-KERNEL-MAPPINGS

Мета цього документа: показати kernel як коротку класичну схему:

- іменники = типи / суми типів
- дієслова = канонічні morphism-like дії над цими доменами
- DSL = лише поверхневий запис, який зводиться до kernel

## 1. Objects

### Ресурси

- `Principal`
- `Session`
- `Feed`
- `Message`
- `Group`

### Події

- `Event`

### Спостереження

- `Observation`

### Твердження

- `Predicate`

### Стан

- `State`

### Семантичні судження

- `Judgment`

Усі іменники живуть у типах kernel. Вони не є DSL-командами.

## 2. Morphisms

Kernel `action` layer містить канонічні дієслова:

- `SessionOp`
- `Post`
- `Mutate`
- `MarkRead`
- `Replay`
- `View`
- `ChangeRelation`
- `ChangeRole`
- `ChangeModeration`

Це не surface syntax, а канонічні переходи системи.

## 3. Semantic Separation

`Event ≠ Action`

`Action` може породжувати `Event`, але `Event` не є `Action`.

| Layer | Роль |
| --- | --- |
| `Action` | що виконується |
| `Event` | що відбулося |
| `Observation` | що спостерігається |
| `Predicate` | що перевіряється в `expect` |
| `Judgment` | яка семантична форма це фіксує |

У короткій формі:

- `State × Action -> State` задається через `Steps`
- `State × Action -> Observation` задається через `Produces`
- `State ⊨ Predicate` задається через `Satisfies`

Тому `expect event ...` не є `Action`.
Це `Predicate` над `Observation`, яка містить `Event`.

## 4. DSL -> Kernel -> Semantics

```text
DSL -> Kernel -> Semantics
```

- `DSL` — представницький рівень
- `Kernel` — канонічна модель
- `Semantics` — `Steps`, `Produces`, `Satisfies` та інваріанти

Псевдоніми, символічні та скорочені форми не існують у kernel.
Вони зникають на стадії зведення.

## 5. Mappings

### 5.1 `expect event typing bob1`

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

Розклад:

- `typing` -> `Event`
- `EventObs` -> `Observation`
- `Seen` -> `Predicate`

Форма:

```text
Predicate(Seen(Observation(Event)))
```

### 5.2 `send message to bob "hi"`

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

Класифікація:

- це `Action`
- канонічна дія: `Post`

### 5.3 `edit message`

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

Класифікація:

- це `Action`
- канонічна дія: `Mutate`

### 5.4 `read cursor`

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

Класифікація:

- це `Action`
- канонічна дія: `MarkRead`

### 5.5 `query inbox`

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

Класифікація:

- це `Action`
- канонічна дія: `View`

### 5.6 `query events ... after snapshot`

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

Класифікація:

- це `Action`
- канонічна дія: `Replay`
- у refined kernel це `AfterFeedSnapshot` / `AfterHomeSnapshot`
- у semantic kernel цьому відповідає загальніша форма `AfterSnapshot`

## 6. Minimal Rule

Щоб читати DSL без OCaml-коду, достатньо пам'ятати одне правило:

- якщо DSL щось робить, це зводиться до `Action`
- якщо DSL каже `expect`, це зводиться до `Predicate`
- якщо всередині `expect` стоїть `event`, то це `Predicate(Observation(Event))`, а не `Action`
