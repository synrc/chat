# DSL-SEARCH-KERNEL-EXTENSION

Typed query/view extension для search semantics поверх kernel

## Навіщо це потрібно

Цей документ фіксує search як typed query/view extension поверх core semantic kernel.

Його мета:
- не змішувати search semantics з replay/read semantics;
- показати, як search додається поверх core kernel;
- формалізувати scope, criteria, projection і pagination;
- зафіксувати, що search не створює protocol side effects;
- зафіксувати, що search поважає visibility / ABAC / moderation / membership.

Це не окремий feed.
Це не event stream.
Це query/view extension.

---

## Базовий принцип

Search:

- не змінює `Message/Event` semantics;
- не означає `read`;
- не рухає replay cursor;
- не створює new protocol state;
- не замінює `Inbox/Home/Replay`;
- працює як projection/filter layer над already visible message space.

Тобто search живе поверх:

- `action`
- `observation`
- `predicate`

але не змінює core transition model.

---

## Typed extension

```ocaml
module SearchExt = struct
  open Kernel

  (* ---------- search query ---------- *)

  type search_scope =
    | ScopeAll
    | ScopePeer of principal
    | ScopeGroup of existing_group

  type search_criteria =
    | TextLike of string
    | FieldLike of {
        field : string;
        value : string;
      }
    | FieldEqual of {
        field : string;
        value : string;
      }

  type projection =
    | AllFields
    | OnlyFields of string list

  type search_query = {
    scope : search_scope;
    criteria : search_criteria;
    projection : projection;
    limit : int option;
    page : page_boundary option;
  }

  (* ---------- search action ---------- *)

  type search_action =
    | Search of {
        session : session_id;
        actor : principal;
        query : search_query;
      }

  (* ---------- search result ---------- *)

  type search_item = {
    target : existing_message;
    projected_payload : payload option;
  }

  type search_observation =
    | SearchResult of {
        scope : search_scope;
        items : search_item list;
        count : int;
        has_more : bool;
        next : continuation option;
      }

  (* ---------- search predicates ---------- *)

  type search_predicate =
    | ResultItems
    | ResultCount of cmp
    | HasNext
    | SearchShows of existing_message
    | SearchHides of existing_message
    | ProjectionPreserved
end
```

---

## Що тут є новим primitive

### 1. `search_scope`

Search не працює на raw token strings.
До typed extension повинні доходити лише нормалізовані scopes:

- `ScopeAll`
- `ScopePeer ...`
- `ScopeGroup ...`

Тобто:
- global search;
- peer-scoped search;
- group-scoped search.

### 2. `search_criteria`

На цьому етапі зафіксовано мінімальний набір:

- text-like search;
- field-like search;
- field-equal search.

Це покриває поточний DSL-SEARCH surface.

### 3. `projection`

Projection не змінює matching semantics.
Вона змінює лише shape result item.

### 4. `search_action`

Search краще тримати як extension-action, а не як overloaded `View`.

Причина:
- search має власні criteria;
- search має власну projection semantics;
- search має свій continuation chain;
- search не тотожний `Inbox/Home`.

### 5. `search_observation`

Search result — це не `ViewObs` із core kernel.
Це окремий typed результат.

Причина:
- search повертає `items`;
- search повертає `next`;
- search result shape залежить від projection;
- search має власний stable ordering contract.

---

## Як search extension чіпляється до core kernel

Search extension працює поверх already visible state space.

Тобто pipeline такий:

1. core kernel визначає canonical message space;
2. policy/visibility layer відсікає inaccessible resources і hidden fields;
3. search extension виконує matching поверх видимого простору;
4. projection формує final result shape.

Отже search не повинен:
- обходити visibility;
- обходити moderation;
- обходити membership;
- обходити ABAC field filtering.

---

## Surface-to-extension elaboration

Surface DSL search forms не повинні потрапляти в runner як raw text.

Вони elaborates у typed `search_query`.

### Text search

```text
query search text "draft"
query search peer alice text "draft"
query search group room1 text "draft"
```

elaborates у:

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopeAll;
    criteria = TextLike "draft";
    projection = AllFields;
    limit = None;
    page = None;
  };
}
```

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopePeer (Principal "alice");
    criteria = TextLike "draft";
    projection = AllFields;
    limit = None;
    page = None;
  };
}
```

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopeGroup (ExistingGroup (FeedName "room1"));
    criteria = TextLike "draft";
    projection = AllFields;
    limit = None;
    page = None;
  };
}
```

### Fielded search

```text
query search peer alice field body like "draft"
query search group room1 field tag equal "release"
```

elaborates у:

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopePeer (Principal "alice");
    criteria = FieldLike { field = "body"; value = "draft" };
    projection = AllFields;
    limit = None;
    page = None;
  };
}
```

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopeGroup (ExistingGroup (FeedName "room1"));
    criteria = FieldEqual { field = "tag"; value = "release" };
    projection = AllFields;
    limit = None;
    page = None;
  };
}
```

### Projection

```text
query search peer alice field body like "draft" return body tag
```

elaborates у:

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopePeer (Principal "alice");
    criteria = FieldLike { field = "body"; value = "draft" };
    projection = OnlyFields ["body"; "tag"];
    limit = None;
    page = None;
  };
}
```

### Search pagination

```text
query search peer alice text "draft" limit 2
query search continue
```

first page elaborates у:

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopePeer (Principal "alice");
    criteria = TextLike "draft";
    projection = AllFields;
    limit = Some 2;
    page = None;
  };
}
```

continue elaborates у:

```ocaml
Search {
  session = SessionId "...";
  actor = Principal "...";
  query = {
    scope = ScopeAll;   (* restored from continuation context, not from syntax *)
    criteria = TextLike "draft";
    projection = AllFields;
    limit = Some 2;
    page = Some (Continue (Continuation "..."));
  };
}
```

Отже `query search continue` не є самодостатнім surface термом.
Elaboration повинен відновити original search chain через continuation environment.

---

## Search result observation

Search result не є mutation і не є replay stream.

Він має вигляд:

```ocaml
SearchResult {
  scope = ...;
  items = ...;
  count = ...;
  has_more = ...;
  next = ...;
}
```

### Example

```ocaml
SearchResult {
  scope = ScopePeer (Principal "alice");
  items = [
    {
      target = ExistingMessage { feed = Private (...); id = MessageId "m1" };
      projected_payload = Some {
        body = "draft v1";
        fields = [("tag", Atom "release")];
      };
    }
  ];
  count = 1;
  has_more = false;
  next = None;
}
```

---

## Search predicates

Surface expectations типу:

- `expect result items`
- `expect result items <= 2`
- `expect more`
- `expect next`
- `expect message ...`
- `expect projection preserved`

мають elaborates у search predicates.

### Result count

```text
expect result items <= 2
```

elaborates у:

```ocaml
ResultCount (Le 2)
```

### More / next

```text
expect more
expect next
```

elaborates у:

```ocaml
HasMore
HasNext
```

або `has_more = true` + `next != None` у термінах search observation checking.

### Visibility expectations

```text
expect message m1 visible
expect message m2 hidden
```

у search context краще мислити не як raw visibility facts,
а як expectations щодо result membership:

```ocaml
SearchShows (ExistingMessage { ... })
SearchHides (ExistingMessage { ... })
```

---

## Operational search sketch

Позначення:

- Σ — core state
- Π — policy / visibility context
- q — search query
- r — search result

### SEARCH

visible_space(Σ, Π, actor, scope(q)) = V
matches(V, criteria(q)) = M
project(M, projection(q)) = P
page(P, limit(q), page(q)) = R

──────────────────────────────────────── SEARCH
(Σ, Π) ⊢ Search(session, actor, q) ⇓ SearchResult R

### SEARCH-NO-SIDE-EFFECT

──────────────────────────────────────── SEARCH-STATE
(Σ, Π) ⊢ Search(session, actor, q) ⇝ Σ

Тобто search result породжується як observation,
але state не змінюється.

---

## Семантичні інваріанти search

### 1. Search does not imply read

Search не повинен:
- оновлювати `ReadState`;
- рухати replay cursor;
- генерувати read events.

### 2. Search respects visibility

Search не повинен повертати:
- hidden message;
- hidden field;
- inaccessible scope.

### 3. Projection does not affect matching

Projection визначає лише final result shape,
але не впливає на те, які items match-яться.

### 4. Projection does not affect ordering

Ordering задається server-side search evaluation order
і не повинен змінюватися лише через projection.

### 5. Search continue extends the same chain

`query search continue` має продовжувати саме той самий result chain,
що був створений first page запитом.

### 6. Search has no snapshot isolation by default

Якщо underlying data змінюються між page 1 і continue,
result window може змінитися.

### 7. Stable order only for unchanged result set

Якщо result set не змінюється,
той самий query повинен давати той самий item order.

---

## Що не входить у цей extension

Свідомо не входить:

- ranking model;
- stemming;
- fuzzy matching;
- snippets / highlighting;
- explicit `sortBy`;
- pinned search snapshot;
- full-text index implementation details;
- backend-specific search syntax.

---

## Практичний сенс

Цей extension потрібен для того, щоб:

- search жив не лише як prose semantics;
- було чітко видно, що search — це query/view layer;
- result shaping, projection і continue semantics були формалізовані;
- search не змішувався з replay/read/feed model.

---

## Головний інваріант extension layer

Search extension не повинен:

- змінювати core state;
- створювати read side effects;
- обходити policy layer;
- трактувати search result як event stream;
- змішувати search continuation з replay boundary.

Search повинен лише:
- формувати search query;
- породжувати search observation;
- давати predicates для перевірки result set semantics.
