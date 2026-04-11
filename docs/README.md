# Protocol Documentation

Документація протоколу організована за рівнями: Spec → Kernel → DSL → Extensions.

---

## Spec

- [SPEC](./spec/SPEC.md)
- [ARCH-AUTH](./spec/ARCH-AUTH.md)

Описує архітектуру системи та загальні принципи.

---

## Kernel

- [DSL-SEMANTIC-KERNEL](./kernel/DSL-SEMANTIC-KERNEL.md)
- [DSL-TYPED-KERNEL-REFINEMENT](./kernel/DSL-TYPED-KERNEL-REFINEMENT.md)

Формальна модель:
- state
- action
- observation
- predicate
- judgment

Це джерело істини для всієї системи.

---

## DSL

### Core

- [DSL-CORE](./dsl/core/DSL-CORE.md)

### Advanced

- [DSL-ADVANCED](./dsl/advanced/DSL-ADVANCED.md)
- [DSL-INVARIANTS](./dsl/advanced/DSL-INVARIANTS.md)

### Domain

- [DSL-ROSTER](./dsl/domain/DSL-ROSTER.md)
- [DSL-READ](./dsl/domain/DSL-READ.md)
- [DSL-REPLAY](./dsl/domain/DSL-REPLAY.md)
- [DSL-PAGINATION](./dsl/domain/DSL-PAGINATION.md)
- [DSL-HOME](./dsl/domain/DSL-HOME.md)
- [DSL-VISIBILITY](./dsl/domain/DSL-VISIBILITY.md)
- [DSL-MENTIONS](./dsl/domain/DSL-MENTIONS.md)
- [DSL-PRESENCE](./dsl/domain/DSL-PRESENCE.md)
- [DSL-GROUP](./dsl/domain/DSL-GROUP.md)
- [DSL-MODERATION](./dsl/domain/DSL-MODERATION.md)
- [DSL-PAYLOAD](./dsl/domain/DSL-PAYLOAD.md)

### Coverage

- delivery
- roster / relation
- read / unread
- replay / recovery
- gap handling
- pagination
- home bootstrap / view
- visibility / filtering
- mentions
- presence
- payload / mutation
- group
- moderation
- cross-layer invariants
- version
- federation

---

## Extensions

### Auth

- [DSL-AUTH-KERNEL-EXTENSION](./extensions/auth/DSL-AUTH-KERNEL-EXTENSION.md)
- [DSL-AUTH](./extensions/auth/DSL-AUTH.md)

Authentication, session lifecycle, tokens.

---

### ABAC

- [DSL-ABAC-KERNEL-EXTENSION](./extensions/abac/DSL-ABAC-KERNEL-EXTENSION.md)
- [DSL-ABAC](./extensions/abac/DSL-ABAC.md)

Authorization, visibility, policy.

---

### Search

- [DSL-SEARCH-KERNEL-EXTENSION](./extensions/search/DSL-SEARCH-KERNEL-EXTENSION.md)
- [DSL-SEARCH](./extensions/search/DSL-SEARCH.md)

Query/view layer, projection, filtering.

---

## Принцип

DSL → elaboration → kernel → evaluation

- DSL — сценарії
- Kernel — істина
- Extensions — правила доступу та поведінки
