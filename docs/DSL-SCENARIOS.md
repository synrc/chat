# DSL Scenarios

## Purpose

DSL використовується як інструмент проєктування протоколу через сценарії.

## Structure

- [DSL-CORE.md](./DSL-CORE.md) — grammar, duality, expect semantics
- [DSL-AUTH.md](./DSL-AUTH.md) — auth/session lifecycle
- [DSL-ROSTER.md](./DSL-ROSTER.md) — roster / subscription / p2p relation
- [DSL-READ.md](./DSL-READ.md) — read/cursor/multi-session/multi-feed/unread boundary
- [DSL-REPLAY.md](./DSL-REPLAY.md) — replay/gap/snapshot recovery / home bootstrap
- [DSL-PAGINATION.md](./DSL-PAGINATION.md) — inbox pagination and event streaming / home bootstrap
- [DSL-HOME.md](./DSL-HOME.md) — home/bootstrap/view semantics
- [DSL-VISIBILITY.md](./DSL-VISIBILITY.md) — visible/hidden/field-level visibility
- [DSL-MENTIONS.md](./DSL-MENTIONS.md) — mention-derived view semantics
- [DSL-PRESENCE.md](./DSL-PRESENCE.md) — presence / protocol-observable presence events
- [DSL-INVARIANTS.md](./DSL-INVARIANTS.md) — cross-layer consistency / invariants
- [DSL-ADVANCED.md](./DSL-ADVANCED.md) — conflict semantics, version, federation
- [DSL-GROUP.md](./DSL-GROUP.md) — group
- [DSL-MODERATION.md](./DSL-MODERATION.md) — moderation / block policy
- [DSL-PAYLOAD.md](./DSL-PAYLOAD.md) — structured payload
- [DSL-ABAC.md](./DSL-ABAC.md) — access policy / ABAC scenarios

## Coverage

- delivery
- auth
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
- access policy / ABAC
- cross-layer invariants
- version
- federation

Unread semantics окремо не винесені в окремий файл,
оскільки на цьому етапі вони вже покриті в DSL-READ.md
разом із read/cursor semantics.