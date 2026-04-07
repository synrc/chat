# Typed Refinement семантичного ядра DSL

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
  type principal = Principal of string
  type session_id = SessionId of string
  type feed_name = FeedName of string
  type message_id = MessageId of string
  type seq = Seq of int
  type snapshot = Snapshot of string
  type continuation = Continuation of string

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

  type payload = Payload of (string * value) list

  type msg_addr =
    | ById of message_id

  type replay_boundary =
    | AfterSeq of seq
    | AfterSnapshot of snapshot

  type page_boundary =
    | Continue of continuation

  (* ---------- existing resources ---------- *)

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

  type relation =
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
        rel : relation;
        dst : principal;
        scope : feed option;
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
        rel : [ `Roster | `Subscription ];
        dst : principal;
        add : bool;
      }
    | ChangeRole of {
        session : session_id;
        actor : principal;
        group : existing_group;
        principal : principal;
        role : role;
        add : bool;
      }
    | ChangeModeration of {
        session : session_id;
        actor : principal;
        dst : principal;
        scope : feed option;
        ban : bool;
      }

  (* ---------- events ---------- *)

  type presence_kind =
    | Online
    | Offline
    | Typing

  type event =
    | Received of {
        actor : principal option;
        feed : feed;
        target : existing_message option;
      }
    | Delivered of {
        actor : principal option;
        feed : feed;
        target : existing_message option;
      }
    | Read of {
        actor : principal option;
        boundary : read_boundary;
      }
    | Edited of {
        actor : principal option;
        target : existing_message;
      }
    | Deleted of {
        actor : principal option;
        target : existing_message;
      }
    | Presence of {
        actor : principal option;
        kind : presence_kind;
      }

  (* ---------- observations ---------- *)

  type obs =
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
        snapshot : snapshot option;
        count : int;
        more : bool;
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
    | Seen of obs
    | CountIs of metric * cmp
    | HasMore of bool
    | HasSnapshot
    | NoDuplicates
    | NoGaps
    | AccessIs of permission

  (* ---------- judgments ---------- *)

  type judgment =
    | WellFormedFeed of feed
    | WellFormedAction of action
    | StateHas of state * fact
    | Permits of state * action * permission
    | Steps of state * action * state
    | Produces of state * action * obs
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

### 4. View нормалізовано через `view_kind`

Це прибирає "зоопарк команд" і залишає одну модель

### 5. Mutation працює через `existing_message`

Це головний інваріантний апгрейд

---

## Що це дає

- менше runtime перевірок
- більше інваріантів у типах
- чистіший semantic core
- ближче до formal language thinking

---

## Важлива примітка

Це не фінальна модель.

Це крок у бік більш строгої типізованої семантики,
але без переходу в повноцінну dependent type систему.

Його задача — зробити інваріанти явними і обговорюваними.

