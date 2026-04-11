# DSL-ABAC-KERNEL-EXTENSION

## Навіщо це потрібно

Цей документ фіксує policy-level extension поверх typed semantic kernel DSL.

Його мета:
- не змішувати protocol semantics і policy semantics;
- показати, як ABAC вбудовується поверх core kernel;
- зафіксувати, які нові facts, predicates і judgments потрібні;
- відокремити authorization від state transition;
- відокремити visibility filtering від canonical message state.

Це не заміна core kernel.
Це typed extension над ним.

---

## Базовий принцип

ABAC:

- не змінює `Message/Event/Replay/View` semantics;
- не створює нових protocol events;
- не переписує core state model;
- визначає:
  - чи дозволена дія;
  - чи дозволений query;
  - які resources або fields visible у result view.

Тобто ABAC живе поверх:

- `fact`
- `action`
- `observation`
- `predicate`
- `judgment`

із typed kernel, але не замінює їх.

---

## Які core distinction-и зберігаються

ABAC extension зберігає базові distinction-и typed kernel:

- `View ≠ state ≠ event`
- `permission ≠ transition`
- `group existence ≠ membership`
- `read boundary ≠ message identity`
- `message visibility ≠ field visibility`

Policy layer лише уточнює:

- `Permits`
- `Produces`
- `Satisfies`

але не змінює структуру protocol core.

---

## Typed extension

```ocaml
module AbacExt = struct
  open Kernel

  (* ---------- policy domains ---------- *)

  type clearance =
    | Public
    | Confidential
    | Secret
    | TopSecret

  type branch =
    | Civil
    | Military
    | Intelligence
    | Internal of string

  type field_name = string

  type level_cmp =
    | Dominates
    | Equals
    | Below

  (* ---------- policy facts ---------- *)

  type policy_fact =
    | SubjectClearance of {
        principal : principal;
        clearance : clearance;
      }
    | SubjectBranch of {
        principal : principal;
        branch : branch;
      }
    | MessageClassification of {
        target : existing_message;
        level : clearance;
      }
    | FeedBranch of {
        feed : feed;
        branch : branch;
      }
    | FieldVisibility of {
        target : existing_message;
        field : field_name;
        level : clearance;
      }
    | GlobalBan of {
        principal : principal;
      }
    | ScopedBan of {
        principal : principal;
        scope : feed;
      }

  (* ---------- policy effects ---------- *)

  type visibility =
    | Visible
    | Hidden

  type policy_predicate =
    | AccessAllowed
    | AccessDenied
    | MessageVisibilityIs of {
        target : existing_message;
        visibility : visibility;
      }
    | FieldVisibilityIs of {
        target : existing_message;
        field : field_name;
        visibility : visibility;
      }

  (* ---------- policy judgments ---------- *)

  type policy_judgment =
    | PolicyHas of state * policy_fact
    | Authorizes of state * action * permission
    | VisibleMessage of state * existing_message * visibility
    | VisibleField of state * existing_message * field_name * visibility
end
```

---

## Що тут є новим primitive

### 1. `policy_fact`

Це facts не про protocol state як такий, а про policy-layer.

Наприклад:
- clearance subject-а;
- branch subject-а;
- classification повідомлення;
- branch feed-а;
- field-level visibility;
- global ban;
- scoped ban.

Ці facts не є protocol events.
Вони є умовами для authorization і visibility.

### 2. `visibility`

ABAC повинен уміти відділити:

- дозволений query;
- видимий result item;
- видиме поле.

Тому `Visible / Hidden` вводиться окремо від `Allowed / Denied`.

### 3. `policy_judgment`

ABAC extension повинен мати свої judgments, а не лише перевикористовувати core `Permits`.

Причина проста:
- доступ до дії;
- доступ до повідомлення у view;
- доступ до поля у view;

це різні semantic relation-и.

---

## Як ABAC extension чіпляється до core kernel

### 1. `Authorizes` уточнює `Permits`

Core kernel already має:

```ocaml
Permits of state * action * permission
```

ABAC extension задає policy-layer правила, за якими цей judgment виводиться.

Інакше кажучи:

- core kernel містить форму judgment;
- ABAC extension уточнює правила його виведення.

### 2. `VisibleMessage` і `VisibleField` уточнюють `Produces`

Core action може бути дозволений, але observation result може бути відфільтрований.

Наприклад:
- `View(Home ...)` дозволений;
- але частина message items hidden;
- або message visible, але частина fields hidden.

Тому `Produces` і `Satisfies` можуть залежати від ABAC judgments.

---

## Surface-to-extension elaboration

Surface ABAC forms не переходять напряму в core kernel.
Вони elaborates у `policy_fact` / `policy_predicate`.

### Subject attributes

```text
given alice has clearance secret
given alice has branch military
```

elaborates у:

```ocaml
PolicyHas (
  sigma,
  SubjectClearance {
    principal = Principal "alice";
    clearance = Secret;
  }
)

PolicyHas (
  sigma,
  SubjectBranch {
    principal = Principal "alice";
    branch = Military;
  }
)
```

### Message classification

```text
given message m1 has classification secret
```

після message resolution:

```ocaml
PolicyHas (
  sigma,
  MessageClassification {
    target = ExistingMessage { feed = ...; id = MessageId "m1" };
    level = Secret;
  }
)
```

### Feed branch

```text
given feed room1 has branch military
```

elaborates у:

```ocaml
PolicyHas (
  sigma,
  FeedBranch {
    feed = Group (FeedName "room1");
    branch = Military;
  }
)
```

### Ban

```text
given bob is banned
given bob is banned in group room1
```

elaborates у:

```ocaml
PolicyHas (
  sigma,
  GlobalBan {
    principal = Principal "bob";
  }
)

PolicyHas (
  sigma,
  ScopedBan {
    principal = Principal "bob";
    scope = Group (FeedName "room1");
  }
)
```

### Field visibility

```text
given message m1 field attachment visible at level secret
```

elaborates у:

```ocaml
PolicyHas (
  sigma,
  FieldVisibility {
    target = ExistingMessage { feed = ...; id = MessageId "m1" };
    field = "attachment";
    level = Secret;
  }
)
```

---

## Expect-level elaboration

Surface policy expectations не повинні напряму зливатися з core `predicate`.

Краще мислити так:

- `expect access allowed` -> policy predicate
- `expect access denied` -> policy predicate
- `expect message m1 visible` -> visibility predicate
- `expect message m1 field body hidden` -> field visibility predicate

### Access expectations

```text
expect access allowed
expect access denied
```

elaborates у:

```ocaml
AccessAllowed
AccessDenied
```

### Message visibility

```text
expect message m1 visible
expect message m2 hidden
```

elaborates у:

```ocaml
MessageVisibilityIs {
  target = ExistingMessage { feed = ...; id = MessageId "m1" };
  visibility = Visible;
}

MessageVisibilityIs {
  target = ExistingMessage { feed = ...; id = MessageId "m2" };
  visibility = Hidden;
}
```

### Field visibility

```text
expect message m1 field body visible
expect message m1 field attachment hidden
```

elaborates у:

```ocaml
FieldVisibilityIs {
  target = ExistingMessage { feed = ...; id = MessageId "m1" };
  field = "body";
  visibility = Visible;
}

FieldVisibilityIs {
  target = ExistingMessage { feed = ...; id = MessageId "m1" };
  field = "attachment";
  visibility = Hidden;
}
```

---

## Operational policy sketch

Позначення:

- Σ — core state
- Π — policy facts
- a — action
- o — observation

### Clearance-based allow

SubjectClearance(p, c1) ∈ Π
MessageClassification(m, c2) ∈ Π
c1 >= c2

──────────────────────────────────────── ABAC-ALLOW-MESSAGE
(Σ, Π) ⊢ Authorizes(a, Allowed)

### Clearance-based deny

SubjectClearance(p, c1) ∈ Π
MessageClassification(m, c2) ∈ Π
c1 < c2

──────────────────────────────────────── ABAC-DENY-MESSAGE
(Σ, Π) ⊢ Authorizes(a, Denied)

### Global ban override

GlobalBan(p) ∈ Π

──────────────────────────────────────── ABAC-DENY-GLOBAL-BAN
(Σ, Π) ⊢ Authorizes(a, Denied)

### Scoped ban override

ScopedBan(p, f) ∈ Π
action_scope(a) = f

──────────────────────────────────────── ABAC-DENY-SCOPED-BAN
(Σ, Π) ⊢ Authorizes(a, Denied)

### Field visibility

FieldVisibility(m, field, req) ∈ Π
SubjectClearance(p, cur) ∈ Π
cur >= req

──────────────────────────────────────── ABAC-FIELD-VISIBLE
(Σ, Π) ⊢ VisibleField(m, field, Visible)

FieldVisibility(m, field, req) ∈ Π
SubjectClearance(p, cur) ∈ Π
cur < req

──────────────────────────────────────── ABAC-FIELD-HIDDEN
(Σ, Π) ⊢ VisibleField(m, field, Hidden)
```

---

## Важливі precedence rules

У цьому extension слід явно зафіксувати такі правила:

1. `Denied` має вищий пріоритет за `Allowed`
2. `GlobalBan` має вищий пріоритет за scoped allow
3. `ScopedBan` має вищий пріоритет за resource allow у цьому scope
4. visibility filtering не змінює canonical message state
5. field visibility не робить message visible автоматично
6. membership і moderation — різні policy dimensions
7. allowed query не означає повну видимість result set

---

## Що не входить у цей extension

Свідомо не входить:

- policy administration workflow;
- dynamic policy updates як protocol event stream;
- external PDP/PIP/PAP model;
- delegation / token issuance;
- full XACML-подібна policy language;
- obligations / advice;
- conflict resolution beyond basic deny-overrides.

---

## Практичний сенс

Цей extension потрібен для того, щоб:

- ABAC сценарії не жили лише як prose examples;
- policy layer була узгоджена з typed kernel;
- `access allowed/denied`, `visible/hidden`, field filtering були виражені формально;
- runner з часом міг мати окремий policy evaluation phase.

---

## Головний інваріант extension layer

ABAC extension не повинен:

- переписувати core protocol state;
- створювати нові Message/Event semantics;
- трактувати filtering як mutation;
- змішувати authorization і observation filtering.

ABAC повинен лише:
- обчислювати `permission`;
- визначати `visibility`;
- уточнювати `Produces` / `Satisfies` поверх core kernel.
