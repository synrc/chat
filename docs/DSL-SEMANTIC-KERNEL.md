# Семантичне ядро DSL

## Навіщо це потрібно

Цей документ фіксує нижчий рівень моделі, ніж поточний DSL surface.

Його мета:
- відокремити semantic core від surface syntax;
- звести canonical/exact форми до спільного ядра;
- розвести facts, actions, observations і judgments;
- дати основу для подальшого обговорення AST, elaboration і type-driven моделі.

Це не surface DSL і не runner-oriented AST.
Це спроба описати мінімальне ядро, в яке surface DSL може зводитися після elaboration.

---

## Що не входить у ядро

У це ядро свідомо **не** входять:
- canonical/exact duality як така;
- short forms і syntactic sugar;
- `ref` як DSL-level local reference;
- `capture id as`;
- symbolic cursor forms типу `cursor`, `next`, `last`;
- окремі surface-команди на кшталт `send message`, `query home`, `expect message`;
- parser/CST-рівень;
- runner-specific технічні деталі.

Усе це має жити **вище**: на surface/elaboration рівні.

---

## Основна ідея

Поверхневий DSL можна мислити так:
- `given` описує state;
- runtime команди описують actions;
- `expect` описує assertions над state або observations.

У ядрі це стискається до кількох форм:
- `fact` — що істинне про світ;
- `action` — що робить агент;
- `obs` — що можна спостерігати;
- `predicate` — що саме стверджує сценарій;
- `judgment` — формальна форма твердження про well-formedness, state, transition, observation або satisfaction.

---

## Канонічне ядро

```ocaml
module Kernel = struct
  type principal = string
  type session_id = string
  type feed_name = string
  type message_id = string
  type seq = int
  type snapshot = string
  type continuation = string

  (* ---------- formation layer ---------- *)

  type feed =
    | Private of principal * principal
    | Group of feed_name
    | Token of string

  type value =
    | Str of string
    | Int of int
    | Bool of bool
    | Atom of string

  (* normalized application-level payload *)
  type payload = (string * value) list

  (* canonical message identity for mutation / stable addressing *)
  type addr =
    | ById of message_id

  (* replay boundary only; no cursor/next/last sugar in kernel *)
  type replay_boundary =
    | AfterSeq of seq
    | AfterSnapshot of snapshot

  (* pagination continuation only; separate from replay boundary *)
  type page =
    | Continue of continuation

  (* ---------- fact layer ---------- *)

  type fact =
    | GroupExists of feed_name
    | MessageAt of {
        feed : feed;
        pos : seq;
        id : message_id option;
        author : principal;
        payload : payload;
      }
    | ReadAt of {
        principal : principal;
        feed : feed;
        up_to : seq;
      }
    | RoleAt of {
        principal : principal;
        feed : feed;
        role : [ `Owner | `Member ];
      }
    | Rel of {
        src : principal;
        kind : [ `Roster | `Subscription | `Moderation ];
        dst : principal;
        scope : feed option;
      }

  (* ---------- permission layer ---------- *)

  type permission =
    | Allowed
    | Denied

  (* ---------- action layer ---------- *)

  type action =
    | SessionOp of {
        session : session_id;
        actor : principal;
        op : [ `Connect | `Disconnect | `Authenticate | `Resume | `Renew ];
      }
    | Post of {
        session : session_id;
        actor : principal;
        feed : feed;
        payload : payload;
      }
    | Alter of {
        session : session_id;
        actor : principal;
        target : addr;
        change : [ `Set of payload | `Delete ];
      }
    | MarkRead of {
        session : session_id;
        actor : principal;
        feed : feed;
        up_to : seq;
      }
    | Replay of {
        session : session_id;
        actor : principal;
        feed : feed;
        after : replay_boundary option;
        limit : int option;
      }
    | HomeView of {
        session : session_id;
        actor : principal;
        limit : int option;
        preview : int option;
        page : page option;
      }
    | InboxView of {
        session : session_id;
        actor : principal;
        feed : feed;
        limit : int option;
        page : page option;
      }
    | RosterView of {
        session : session_id;
        actor : principal;
      }
    | GroupsView of {
        session : session_id;
        actor : principal;
      }
    | MembersView of {
        session : session_id;
        actor : principal;
        feed : feed;
      }
    | ModerationView of {
        session : session_id;
        actor : principal;
        scope : feed option;
      }
    | SubscriptionsView of {
        session : session_id;
        actor : principal;
      }
    | ChangeRel of {
        session : session_id;
        actor : principal;
        kind : [ `Roster | `Subscription ];
        dst : principal;
        add : bool;
      }
    | ChangeRole of {
        session : session_id;
        actor : principal;
        feed : feed;
        principal : principal;
        role : [ `Owner | `Member ];
        add : bool;
      }
    | ChangeModeration of {
        session : session_id;
        actor : principal;
        dst : principal;
        scope : feed option;
        ban : bool;
      }

  (* ---------- observation layer ---------- *)

  type event =
    | ReceivedEvt of {
        actor : principal option;
        feed : feed;
        target : addr option;
      }
    | DeliveredEvt of {
        actor : principal option;
        feed : feed;
        target : addr option;
      }
    | ReadEvt of {
        actor : principal option;
        feed : feed;
        up_to : seq;
      }
    | EditEvt of {
        actor : principal option;
        target : addr;
      }
    | DeleteEvt of {
        actor : principal option;
        target : addr;
      }
    | PresenceEvt of {
        actor : principal option;
        kind : [ `Online | `Offline | `Typing ];
      }

  type obs =
    | MsgObs of {
        feed : feed;
        id : message_id option;
        pos : seq option;
        author : principal;
        payload : payload;
      }
    | EventObs of event
    | HomeObs of {
        snapshot : snapshot option;
        count : int;
        more : bool;
      }
    | InboxObs of {
        feed : feed;
        snapshot : snapshot option;
        count : int;
        more : bool;
      }
    | CollectionObs of {
        kind : [ `Roster | `Groups | `Members of feed | `Moderation of feed option | `Subscriptions ];
        count : int;
        more : bool;
      }

  (* ---------- satisfaction layer ---------- *)

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

  (* ---------- judgment layer ---------- *)

  type state = fact list

  type judgment =
    | FormedFeed of feed
    | FormedAddr of addr
    | FormedAction of action
    | StateHas of state * fact
    | Permits of state * action * permission
    | Steps of state * action * state
    | Produces of state * action * obs
    | Satisfies of state * predicate
    | Elaborates of string * predicate
end
```

---

## Пояснення по шарах

### 1. Formation layer

Це мінімальний набір сутностей, з яких будується мова:
- `feed` — ресурс/стрім;
- `value` — атомарні значення payload;
- `payload` — нормалізований application-level payload;
- `addr` — канонічна stable identity для mutation;
- `replay_boundary` — boundary для replay;
- `page` — continuation для pagination.

Тут уже немає surface-речей типу `peer`, `group`, `ref`, `cursor`, `next`, `last`.
Після elaboration має лишитися тільки це.

Важливе уточнення: pagination continuation і replay boundary розведені окремо.
Це зроблено, щоб не змішувати `query home continue` / `query inbox continue`
з `after seq` / `after snapshot`.

### 2. Fact layer

`fact` описує, що є істинним про state:
- існує group resource;
- повідомлення існує в feed на певній позиції;
- read cursor стоїть на певному `seq`;
- користувач має роль у group/feed;
- між двома principals існує relation.

Це по суті semantic основа для `given`.

Окремий `GroupExists` потрібен, щоб не змішувати existence group resource
з membership/role state.

### 3. Permission layer

`permission` фіксує, чи дозволена дія.

Це окремий шар, бо доступність дії і сама дія — різні речі.

### 4. Action layer

`action` — це не surface-команди, а узагальнені transition forms:
- `SessionOp`
- `Post`
- `Alter`
- `MarkRead`
- `Replay`
- `HomeView`
- `InboxView`
- `RosterView`
- `GroupsView`
- `MembersView`
- `ModerationView`
- `SubscriptionsView`
- `ChangeRel`
- `ChangeRole`
- `ChangeModeration`

Тобто не `send message`, `query home`, `ban bob`, а більш фундаментальні типи переходів.

Важливе уточнення: actions тут є session-aware.
Це зроблено, щоб kernel був ближчим до самого протоколу,
де session context є важливим transport/runtime координатним шаром,
навіть якщо деякі state semantics лишаються user-scoped.

### 5. Observation layer

`obs` — це те, що реально можна спостерігати:
- повідомлення як observation;
- подія як runtime truth;
- home result;
- inbox result;
- collection/view result.

Тут важливий поділ між:
- state;
- runtime event;
- view response.

Окремі `HomeObs` і `InboxObs` лишені спеціально,
щоб не втратити різницю між shared home snapshot semantics
і feed-scoped inbox semantics.

### 6. Satisfaction layer

`predicate` — це вже не DSL-вокабуляр, а узагальнені форми тверджень:
- `Holds`
- `Seen`
- `CountIs`
- `HasMore`
- `NoDuplicates`
- `NoGaps`
- `AccessIs`

Тобто surface `expect ...` форми мають зводитися до таких предикатів.

### 7. Judgment layer

`judgment` — це вже формальні судження над ядром:
- що є well-formed;
- що входить у state;
- що дозволено;
- як виконується transition;
- що продукується як observation;
- що задовольняє predicate;
- як surface форма elaborates у kernel form.

Саме цей шар і є найближчим до "мовного" рівня у строгому сенсі.

---

## Як surface DSL стискається до ядра

### Повідомлення

```text
send message to bob "hi"
```

після elaboration:

```ocaml
FormedAction (
  Post {
    actor = "alice";
    feed = Private ("alice", "bob");
    payload = [("body", Str "hi")];
  }
)
```

### Mutation

```text
edit message id m1id body "v2"
```

після resolution:

```ocaml
FormedAction (
  Alter {
    session = "alice1";
    actor = "alice";
    target = ById "msg-123";
    change = `Set [("body", Str "v2")];
  }
)
```

### Read

```text
send read peer alice for last
```

після elaboration `last -> concrete seq`:

```ocaml
FormedAction (
  MarkRead {
    session = "bob1";
    actor = "bob";
    feed = Private ("bob", "alice");
    up_to = 123;
  }
)
```

### Replay / View

```text
query events peer bob after snapshot
```

після elaboration:

```ocaml
FormedAction (
  Replay {
    session = "alice1";
    actor = "alice";
    feed = Private ("alice", "bob");
    after = Some (AfterSnapshot "snap-1");
    limit = None;
  }
)
```

```text
bootstrap home limit 20 preview 1
```

після elaboration:

```ocaml
FormedAction (
  HomeView {
    session = "alice1";
    actor = "alice";
    limit = Some 20;
    preview = Some 1;
    page = None;
  }
)
```

### Given

```text
given alice has bob in roster
```

зводиться до факту:

```ocaml
StateHas (
  [],
  Rel {
    src = "alice";
    kind = `Roster;
    dst = "bob";
    scope = None;
  }
)
```

### Expect

```text
expect event offline bob
```

зводиться до predicate/judgment:

```ocaml
Satisfies (
  [],
  Seen (
    EventObs (
      PresenceEvt {
        actor = Some "bob";
        kind = `Offline;
      }
    )
  )
)
```

```text
expect shared snapshot
```

зводиться до:

```ocaml
Satisfies ([], HasSnapshot)
```

---

## Узгодження з протоколом

Поточна версія kernel спеціально підправлена так,
щоб бути ближчою не лише до DSL semantics,
а й до самого протоколу.

Основні корекції:
- actions зроблено session-aware;
- replay boundary і pagination continuation розведено окремо;
- повернуто окремий факт `GroupExists`;
- mutation канонізовано до стабільної `message_id` адресації;
- event layer розширено до `received / delivered / read / edit / delete / presence`;
- home/inbox observations розведено окремо, щоб не втратити різницю між shared snapshot і feed-scoped snapshot semantics.

Тобто це вже не просто "теоретичний" kernel,
а спроба зберегти в ядрі ті distinction-и,
які реально важливі для узгодження з CHAT protocol semantics.

---

## Практичний сенс цього ядра

Це ядро корисне не для того, щоб ним напряму писати сценарії.

Його практичний сенс такий:
- мати спільну semantic основу під canonical і exact DSL;
- чітко відокремити sugar від core;
- зробити можливим elaboration у типізовану модель;
- дати основу для AST нижчого рівня;
- дати основу для більш строгого обговорення protocol semantics.

---

## Важлива примітка

Це ядро не претендує на остаточність.

Це робоча спроба звести поточний DSL не до переліку surface-команд,
а до більш канонічного semantic kernel.

Його можна використовувати як точку входу для подальшого обговорення:
- що тут є справжнім primitive;
- що тут ще лишилось занадто surface-like;
- що треба винести на elaboration layer;
- що, навпаки, бракує у самому kernel.

