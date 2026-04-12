# DSL-TYPED-KERNEL-REFINEMENT

Typed refinement семантичного ядра DSL

## Навіщо цей варіант

Цей документ є уточненням до DSL-SEMANTIC-KERNEL.

Його мета — зробити ще один крок від "структурного AST" до моделі,
де типи починають виражати інваріанти системи.

Це не MLTT і не theorem prover.
Це більш строгий, але все ще практичний kernel,
який ближчий до типізованого мислення.

---

## Ключові інваріанти

1. Mutation адресує тільки існуюче повідомлення
2. Delete домінує над Edit
3. Replay boundary ≠ pagination continuation
4. Read cursor — це feed boundary, а не message identity
5. Group existence ≠ membership
6. View ≠ state ≠ event
7. Kernel не містить surface sugar

---

## Typed kernel

```ocaml
module Kernel = struct
  (* ---------- identity / newtypes ---------- *)

  type principal = Principal of string
  type session_id = SessionId of string
  type feed_name = FeedName of string
  type message_id = MessageId of string
  type seq = Seq of int
  type feed_snapshot_id = FeedSnapshotId of string
  type home_snapshot_id = HomeSnapshotId of string
  type continuation = Continuation of string

  type user_actor = principal

  type session_actor = {
    session : session_id;
    principal : principal;
  }

  type 'a actor_match =
    | AnyActor
    | ExactActor of 'a

  (* ---------- formation ---------- *)

  type feed =
    | Private of principal * principal
    | Group of feed_name
    | Token of string

  type value =
    | Str of string
    | Int of int
    | Bool of bool
    | Atom of string

  (* canonical normalized payload:
     - body is mandatory
     - fields are flat only
     - body should not be duplicated in fields *)
  type payload = {
    body : string;
    fields : (string * value) list;
  }

  type replay_boundary =
    | AfterSeq of seq
    | AfterFeedSnapshot of feed_snapshot_id
    | AfterHomeSnapshot of home_snapshot_id

  type page_boundary =
    | Continue of continuation

  type view_snapshot =
    | FeedSnapshot of feed_snapshot_id
    | HomeSnapshot of home_snapshot_id

  (* ---------- validated resources ---------- *)

  type existing_group =
    | ExistingGroup of feed_name

  type existing_message =
    | ExistingMessage of {
        feed : feed;
        id : message_id;
      }

  type read_boundary =
    | ReadBoundary of {
        feed : feed;
        up_to : seq;
      }

  (* ---------- state ---------- *)

  type role =
    | Owner
    | Member

  type relation_kind =
    | Roster
    | Subscription
    | Moderation

  type fact =
    | GroupExists of existing_group
    | MessageExists of {
        feed : feed;
        pos : seq;
        id : message_id option;
        author : principal;
        payload : payload;
      }
    | ReadState of {
        principal : principal;
        boundary : read_boundary;
      }
    | RoleState of {
        principal : principal;
        group : existing_group;
        role : role;
      }
    | RelationState of {
        src : principal;
        kind : relation_kind;
        dst : principal;
        scope : feed option;  (* None = global *)
      }

  type state = State of fact list

  (* ---------- permission ---------- *)

  type permission =
    | Allowed
    | Denied

  (* ---------- actions ---------- *)

  type session_op =
    | Connect
    | Disconnect
    | Authenticate
    | Resume
    | Renew

  type mutation =
    | ReplacePayload of payload
    | Tombstone

  type view_kind =
    | Home
    | Inbox of feed
    | RosterView
    | GroupsView
    | MembersView of existing_group
    | ModerationView of feed option
    | SubscriptionsView

  type action =
    | SessionOp of {
        session : session_id;
        actor : principal;
        op : session_op;
      }
    | Post of {
        session : session_id;
        actor : principal;
        feed : feed;
        payload : payload;
      }
    | Mutate of {
        session : session_id;
        actor : principal;
        target : existing_message;
        op : mutation;
      }
    | MarkRead of {
        session : session_id;
        actor : principal;
        boundary : read_boundary;
      }
    | Replay of {
        session : session_id;
        actor : principal;
        feed : feed;
        after : replay_boundary option;
        limit : int option;
      }
    | View of {
        session : session_id;
        actor : principal;
        kind : view_kind;
        limit : int option;
        preview : int option;
        page : page_boundary option;
      }
    | ChangeRelation of {
        session : session_id;
        actor : principal;
        kind : [ `Roster | `Subscription ];
        dst : principal;
        add : bool;
      }
    | ChangeRole of {
        session : session_id;
        actor : principal;
        group : existing_group;
        target : principal;
        role : role;
        add : bool;
      }
    | ChangeModeration of {
        session : session_id;
        actor : principal;
        target : principal;
        scope : feed option;
        ban : bool;
      }

  (* ---------- events ---------- *)

  type user_presence_kind =
    | Online
    | Offline

  type session_presence_kind =
    | Typing

  type event =
    | Received of {
        actor : user_actor actor_match;
        feed : feed;
        target : existing_message option;
      }
    | Delivered of {
        actor : user_actor actor_match;
        feed : feed;
        target : existing_message option;
      }
    | Read of {
        actor : user_actor actor_match;
        boundary : read_boundary;
      }
    | Edited of {
        actor : user_actor actor_match;
        target : existing_message;
      }
    | Deleted of {
        actor : user_actor actor_match;
        target : existing_message;
      }
    | UserPresence of {
        actor : user_actor actor_match;
        kind : user_presence_kind;
      }
    | SessionPresence of {
        actor : session_actor actor_match;
        kind : session_presence_kind;
      }

  (* ---------- observations ---------- *)

  type observation =
    | MessageObs of {
        feed : feed;
        id : message_id option;
        pos : seq option;
        author : principal;
        payload : payload;
      }
    | EventObs of event
    | ViewObs of {
        kind : view_kind;
        snapshot : view_snapshot option;
        count : int;
        has_more : bool;
      }

  (* ---------- predicates ---------- *)

  type metric =
    | Items
    | Events
    | Feeds

  type cmp =
    | Eq of int
    | Le of int
    | Gt of int

  type predicate =
    | Holds of fact
    | Seen of observation
    | CountIs of metric * cmp
    | HasMore of bool
    | HasSnapshot
    | NoDuplicates
    | NoGaps
    | AccessIs of permission

  (* ---------- judgments ---------- *)

  type judgment =
    | WellFormedFeed of feed
    | WellFormedPayload of payload
    | WellFormedAction of action
    | StateHas of state * fact
    | Permits of state * action * permission
    | Steps of state * action * state
    | Produces of state * action * observation
    | Satisfies of state * predicate
end
```

---

## Що змінилось відносно базового kernel

### 1. Введено "existing_*" типи

- `existing_message`
- `existing_group`

Це означає:
- mutation працює тільки з валідованими об'єктами
- не існує "Edit невідомого повідомлення"

### 2. Введено newtype-подібні обгортки

- `Principal`
- `SessionId`
- `MessageId`
- `Seq`

Це зменшує кількість помилок змішування типів

### 3. Read винесено в окрему сутність

`read_boundary` чітко відокремлює:
- message identity
- feed cursor

При цьому `read_boundary` сам по собі не кодує forward-only progress:
це просто explicit cursor boundary, який може бути і меншим за попередній
effective read state, якщо модель дозволяє rewind.

### 4. View нормалізовано через `view_kind`

Усі view-запити (`home`, `inbox`, `roster`, `groups`, `members`, `moderation`, `subscriptions`)
зводяться до одного конструктора `View`.

Це:
- прибирає "зоопарк команд";
- лишає одну канонічну action-form;
- не губить різницю між самими видами view, бо вона зберігається в `view_kind`.

### 5. Mutation працює через `existing_message`

Kernel не допускає mutation за сирим surface-addressing.
До цього рівня mutation доходить тільки після resolution і validation.

Це означає:
- `edit/delete` не адресують "будь-що";
- mutation працює тільки з уже валідованим `existing_message`;
- elaboration layer відповідає за перетворення surface `id` / `capture id as`
  у kernel-level `existing_message`.

### 6. Payload канонізовано

Payload у refined kernel вже не є просто списком полів.

Він має форму:

- `body` — обов'язкове canonical поле;
- `fields` — flat список додаткових normalized полів.

Це зроблено для того, щоб:
- зафіксувати інваріант `body is mandatory`;
- уникнути двозначності між short message form і structured form;
- зробити elaboration результату `send message ...` канонічним.

### 7. Розведено user-scoped і session-scoped actor semantics

В kernel додано окремі actor-level типи:

- `user_actor`
- `session_actor`

Це дозволяє явно розвести:
- aggregate user-scoped presence (`online` / `offline`);
- session-scoped transient presence (`typing`).

Також wildcard/exact actor matching більше не кодується через `option`,
а винесено в окремий тип:

- `AnyActor`
- `ExactActor ...`

Це прибирає змішування:
- exact actor equality
- wildcard / existential actor match

### 8. Snapshot semantics розщеплено

У kernel тепер окремо існують:

- `feed_snapshot_id`
- `home_snapshot_id`

і окремий `view_snapshot`.

Це фіксує різницю між:
- feed-scoped recovery anchor;
- shared home bootstrap anchor.

Таким чином `snapshot` більше не є одним перевантаженим semantic token.

---

## Що це дає

- менше runtime перевірок
- більше інваріантів у типах
- чистіший semantic core
- ближче до formal language thinking

---

## Surface-to-kernel elaboration notes

Surface DSL не працює напряму з kernel constructors.

Перед переходом у typed kernel виконується elaboration, яка:

- нормалізує canonical / exact syntax;
- розв'язує alias і symbolic forms;
- відновлює explicit actor matching;
- розрізняє feed-scoped і home-scoped snapshot;
- зводить surface expectations до kernel `observation` / `predicate`.

Усі surface sugar форми мають зникнути до моменту побудови kernel term.

### 1. Actor elaboration

Surface DSL може опускати actor або задавати його явно.

#### Exact actor form

```text
expect event read bob up to 12
expect event offline bob
```

після elaboration:

- `bob` -> `ExactActor (Principal "bob")`

Наприклад:

```ocaml
Seen (
  EventObs (
    Read {
      actor = ExactActor (Principal "bob");
      boundary = ReadBoundary { feed = ...; up_to = Seq 12 };
    }
  )
)
```

```ocaml
Seen (
  EventObs (
    UserPresence {
      actor = ExactActor (Principal "bob");
      kind = Offline;
    }
  )
)
```

#### Wildcard actor form

```text
expect event read up to 12
expect event offline
```

після elaboration:

- omitted actor -> `AnyActor`

Наприклад:

```ocaml
Seen (
  EventObs (
    Read {
      actor = AnyActor;
      boundary = ReadBoundary { feed = ...; up_to = Seq 12 };
    }
  )
)
```

```ocaml
Seen (
  EventObs (
    UserPresence {
      actor = AnyActor;
      kind = Offline;
    }
  )
)
```

#### Session-scoped presence

```text
expect event typing bob1
```

або інша surface форма, яка явно адресує session alias,

повинна elaborates у:

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

Тобто:

- `online` / `offline` -> `UserPresence`
- `typing` -> `SessionPresence`

### 2. Snapshot elaboration

Surface token `snapshot` не переходить у kernel напряму.

Під час elaboration він повинен бути розв'язаний у один з двох explicit kernel forms:

- `FeedSnapshot ...`
- `HomeSnapshot ...`

#### Feed-scoped snapshot

```text
query inbox peer bob
expect snapshot

query events peer bob after snapshot
```

Якщо `snapshot` походить з `inbox` / `feed view`, elaboration будує:

```ocaml
AfterFeedSnapshot (FeedSnapshotId "...")
```

і observation:

```ocaml
ViewObs {
  kind = Inbox (...);
  snapshot = Some (FeedSnapshot (FeedSnapshotId "..."));
  count = ...;
  has_more = ...;
}
```

#### Home-scoped snapshot

```text
bootstrap home
expect shared snapshot

query events peer bob after snapshot
```

Якщо `snapshot` походить з `home view`, elaboration будує:

```ocaml
AfterHomeSnapshot (HomeSnapshotId "...")
```

і observation:

```ocaml
ViewObs {
  kind = Home;
  snapshot = Some (HomeSnapshot (HomeSnapshotId "..."));
  count = ...;
  has_more = ...;
}
```

Таким чином surface `snapshot` є лише symbolic placeholder,
а kernel завжди отримує вже disambiguated snapshot kind.

### 3. Session alias elaboration

Surface session context:

```text
session bob1 as bob
```

не переходить у kernel як plain string alias.

Elaboration повинна підтримувати environment:

```ocaml
session_alias -> {
  session : session_id;
  principal : principal;
}
```

Це environment використовується для:

- побудови `session_actor`;
- resolution `peer` відносно поточної session;
- побудови session-scoped presence expectations.

Наприклад:

```text
session bob1 as bob
expect event typing
```

може elaborates у:

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

### 4. Feed resolution

Surface forms:

```text
peer bob
group room1
feed private:bob
```

не зберігаються в kernel.

Після elaboration повинні залишитися лише kernel feeds:

```ocaml
Private (Principal "...", Principal "...")
Group (FeedName "...")
Token "..."
```

#### Peer resolution

У session context:

```text
session alice1 as alice
query events peer bob after 10
```

`peer bob` elaborates у:

```ocaml
Private (Principal "alice", Principal "bob")
```

#### Group resolution

```text
query inbox group room1
```

elaborates у:

```ocaml
Group (FeedName "room1")
```

#### Explicit token

```text
query inbox feed private:bob
```

може або:
- залишатися `Token "private:bob"`,
- або, якщо elaboration policy це дозволяє, нормалізуватися у `Private (...)`.

Це рішення має бути єдиним і послідовним для всієї elaboration layer.

### 5. Symbolic forms

Surface symbolic forms типу:

- `last`
- `cursor`
- `next`
- `snapshot`

не належать kernel.

Вони повинні бути повністю resolved до побудови kernel action / predicate.

#### Read sugar

```text
send read peer alice for last
```

elaborates у конкретний:

```ocaml
MarkRead {
  session = ...;
  actor = ...;
  boundary =
    ReadBoundary {
      feed = Private (...);
      up_to = Seq 123;
    };
}
```

#### Pagination sugar

```text
query home continue
```

elaborates у:

```ocaml
View {
  session = ...;
  actor = ...;
  kind = Home;
  limit = None;
  preview = None;
  page = Some (Continue (Continuation "..."));
}
```

Kernel не повинен отримувати нерозв'язаних symbolic cursor forms.

### 6. Message identity elaboration

Surface forms:

- `ref ...`
- `id ...`
- `capture id as ...`

не входять у typed kernel.

До kernel mutation доходить тільки через:

```ocaml
existing_message
```

Тобто elaboration / resolution layer повинна виконати перетворення:

```text
surface reference -> validated existing_message
```

Наприклад:

```text
send message to bob "hi" capture id as m1id
edit message id m1id body "v2"
```

після resolution:

```ocaml
Mutate {
  session = ...;
  actor = ...;
  target =
    ExistingMessage {
      feed = Private (...);
      id = MessageId "...";
    };
  op = ReplacePayload ...;
}
```

Typed kernel не працює з unresolved aliases або surface references.

### 7. Elaboration invariant

Головний інваріант elaboration layer:

surface DSL може бути неоднозначним, скороченим і context-sensitive,
але typed kernel не повинен містити:

- omitted actor semantics;
- overloaded snapshot token;
- session alias sugar;
- symbolic cursor sugar;
- unresolved message references.

Усі такі distinction-и мають бути explicit вже на kernel-рівні.

## Operational semantics sketch

Позначення:

- Σ — state
- Σ' — новий state
- a — action
- o — observation
- J — predicate

Форми суджень:

- Σ ⊢ a ⇝ Σ' — дія змінює state
- Σ ⊢ a ⇓ o — дія породжує observation
- Σ ⊨ J — state або observation задовольняє predicate

---

### POST

payload well-formed
next_seq(Σ, f) = n
fresh_id() = m

──────────────────────────────────────── POST
Σ ⊢ Post(s, p, f, payload) ⇝
  Σ + MessageExists {
    feed = f;
    pos = n;
    id = Some m;
    author = p;
    payload = payload;
  }

──────────────────────────────────────── POST-OBS
Σ ⊢ Post(s, p, f, payload) ⇓
  MessageObs {
    feed = f;
    id = Some m;
    pos = Some n;
    author = p;
    payload = payload;
  }

---

### EDIT

MessageExists { feed = f; pos = n; id = Some m; author = p; payload = old_payload } ∈ Σ

──────────────────────────────────────── EDIT
Σ ⊢ Mutate(
  s,
  p,
  ExistingMessage { feed = f; id = m },
  ReplacePayload(new_payload)
) ⇝
  Σ[
    MessageExists { feed = f; pos = n; id = Some m; author = p; payload = old_payload }
    :=
    MessageExists { feed = f; pos = n; id = Some m; author = p; payload = new_payload }
  ]

──────────────────────────────────────── EDIT-OBS
Σ ⊢ Mutate(
  s,
  p,
  ExistingMessage { feed = f; id = m },
  ReplacePayload(new_payload)
) ⇓
  EventObs(Edited(actor = ExactActor p, target = ExistingMessage { feed = f; id = m }))

---

### DELETE

MessageExists { feed = f; pos = n; id = Some m; author = p0; payload = payload } ∈ Σ

──────────────────────────────────────── DELETE
Σ ⊢ Mutate(s, p, ExistingMessage { feed = f; id = m }, Tombstone)
⇝ Σ - MessageExists { feed = f; pos = n; id = Some m; author = p0; payload = payload }

──────────────────────────────────────── DELETE-OBS
Σ ⊢ Mutate(s, p, ExistingMessage { feed = f; id = m }, Tombstone)
⇓ EventObs(Deleted(actor = ExactActor p, target = ExistingMessage { feed = f; id = m }))

---

### READ

ReadBoundary { feed = f; up_to = n } = rb

──────────────────────────────────────── READ
Σ ⊢ MarkRead(s, p, rb)
⇝ Σ[
  ReadState { principal = p; boundary = ReadBoundary { feed = f; up_to = _ } }
  :=
  ReadState { principal = p; boundary = rb }
]

──────────────────────────────────────── READ-OBS
Σ ⊢ MarkRead(s, p, rb)
⇓ EventObs(Read(actor = ExactActor p, boundary = rb))

---

### REPLAY

events_after(Σ, f, b, limit) = xs

──────────────────────────────────────── REPLAY
Σ ⊢ Replay(s, p, f, Some b, limit) ⇝ Σ

──────────────────────────────────────── REPLAY-OBS
Σ ⊢ Replay(s, p, f, Some b, limit)
⇓ ViewObs(Inbox f, Some (FeedSnapshot snapshot), count(xs), more(xs))

---

### HOME

home_view(Σ, p, limit, preview, page) = hv

──────────────────────────────────────── HOME
Σ ⊢ View(s, p, Home, limit, preview, page) ⇝ Σ

──────────────────────────────────────── HOME-OBS
Σ ⊢ View(s, p, Home, limit, preview, page)
⇓ ViewObs(Home, Some (HomeSnapshot (snapshot(hv))), count(hv), more(hv))

---

### RELATION

RelationState(src = p, rel = r, dst = q, scope = None) ∉ Σ

──────────────────────────────────────── REL-ADD
Σ ⊢ ChangeRelation(s, p, r, q, true)
⇝ Σ + RelationState(src = p, rel = r, dst = q, scope = None)

RelationState(src = p, rel = r, dst = q, scope = None) ∈ Σ

──────────────────────────────────────── REL-REMOVE
Σ ⊢ ChangeRelation(s, p, r, q, false)
⇝ Σ - RelationState(src = p, rel = r, dst = q, scope = None)

---

### ROLE

GroupExists(g) ∈ Σ

──────────────────────────────────────── ROLE-ADD
Σ ⊢ ChangeRole(s, p0, g, p, role, true)
⇝ Σ + RoleState { principal = p; group = g; role = role }

RoleState { principal = p; group = g; role = role } ∈ Σ

──────────────────────────────────────── ROLE-REMOVE
Σ ⊢ ChangeRole(s, p0, g, p, role, false)
⇝ Σ - RoleState { principal = p; group = g; role = role }

---

### MODERATION

──────────────────────────────────────── MOD-BAN
Σ ⊢ ChangeModeration(s, p, q, scope, true)
⇝ Σ + RelationState { src = p; kind = Moderation; dst = q; scope = scope }

RelationState { src = p; kind = Moderation; dst = q; scope = scope } ∈ Σ

──────────────────────────────────────── MOD-UNBAN
Σ ⊢ ChangeModeration(s, p, q, scope, false)
⇝ Σ - RelationState { src = p; kind = Moderation; dst = q; scope = scope }

---

## Satisfaction rules

### Message observed

o = MessageObs { feed = f; id = id; pos = pos; author = author; payload = payload }

──────────────────────────────────────── SAT-MSG
o ⊨ Seen(o)

---

### Event observed

o = EventObs(e)

──────────────────────────────────────── SAT-EVENT
o ⊨ Seen(o)

---

### HasMore

o = ViewObs { kind = kind; snapshot = snap; count = count; has_more = more }

──────────────────────────────────────── SAT-MORE
o ⊨ HasMore(more)

---

### HasSnapshot

o = ViewObs { kind = kind; snapshot = Some _; count = count; has_more = more }

──────────────────────────────────────── SAT-SNAPSHOT
o ⊨ HasSnapshot

---

### Count

count_of(o, metric) ⊲⊳ n

──────────────────────────────────────── SAT-COUNT
o ⊨ CountIs(metric, cmp)

---

### Fact holds

f ∈ Σ

──────────────────────────────────────── SAT-HOLDS
Σ ⊨ Holds(f)

---

## Важлива примітка

Це не фінальна модель.

Це крок у бік більш строгої типізованої семантики,
але без переходу в повноцінну dependent type систему.

Окремо слід зауважити, що typed kernel тепер фіксує ще три semantic distinction-и:

- user-scoped actor ≠ session-scoped actor;
- exact actor match ≠ wildcard actor match;
- feed snapshot ≠ home snapshot.

Ці розрізнення не повинні більше відновлюватися неявно з контексту.
Вони мають бути явними вже на kernel-рівні.

Його задача — зробити інваріанти явними і обговорюваними.
