> See DSL-CORE.md for language definition

# DSL-DISCOVERY

Сценарії для capability discovery / feature introspection

## Навіщо це потрібно

Discovery extension потрібен для простого capability introspection layer:

- що підтримує server;
- які auth/query/feed/extension capabilities доступні;
- які feature visible для конкретного actor/scope.

Discovery не змінює state, не означає read і не рухає replay cursor.

---

## Surface form

### Canonical

```text
query discover server
query discover auth
query discover extension
query discover group chat1
```

Canonical форма є основною.

### Exact

```text
query discover scope server
query discover scope feed target group:chat1
query discover scope policy filter "actor=bob"
```

Exact форма потрібна там, де треба явно задати `scope`, `target` або `filter`.

`query discover group <name>` є sugar над `query discover scope feed target group:<name>`.

---

## Expect semantics

Discovery result трактується як список `Feature`.

`expect feature <id>`:

- не вимагає exact match усього result;
- перевіряє лише наявність feature;
- є partial / predicate matching;
- не ламається від додаткових або невідомих feature.

Інакше кажучи:

- unknown features MUST NOT break scenario;
- `expect feature X` означає inclusion check, а не equality всього feature set.

---

## DISC-1. Server capabilities

```text
scenario discover server capabilities

session alice
connect
auth

query discover server

expect feature protocol.version
expect feature auth.methods
expect feature query.types
```

- discovery server повертає загальні protocol/server capabilities
- `expect feature` перевіряє inclusion, а не exact list equality

## DISC-2. Auth capabilities

```text
scenario discover auth capabilities

session alice
connect

query discover auth

expect feature auth.methods
expect feature auth.refresh
```

- auth discovery MAY бути доступний ще до повної аутентифікації
- auth discovery не створює session і не означає `authenticated`

## DISC-3. Feed capabilities

```text
scenario discover feed capabilities

session alice
connect
auth

query discover group chat1

expect feature feed.replay
expect feature feed.read_cursor
```

- feed discovery дозволяє introspection для конкретного group target
- target feed не означає replay/read/update самого feed

## DISC-4. Extension list

```text
scenario discover extensions

session alice
connect
auth

query discover extension

expect feature extension.inbox
expect feature extension.search
```

- discovery extension повертає список extension-level capabilities
- додаткові extension feature допустимі

## DISC-5. Ignore unknown features

```text
scenario ignore unknown features

session alice
connect
auth

query discover server

expect feature protocol.version
```

- unknown features MUST NOT break scenario
- сценарій перевіряє лише потрібну feature, а не exact equality всього result

## DISC-6. Discovery does not move replay cursor

```text
scenario discovery does not move replay cursor

session alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor
expect empty replay

query discover server

query events peer alice after cursor
expect empty replay
expect not more
```

- discovery не означає replay
- discovery не рухає replay boundary і не створює event history side effects

## DISC-7. Exact form with explicit scope

```text
scenario exact discovery form

session alice
connect
auth

query discover scope feed target group:chat1

expect feature feed.replay
```

- exact form лишається еквівалентною canonical form
- вона потрібна для явного `scope/target/filter`, але не змінює semantics discovery

## DISC-8. Unsupported discovery scope

```text
scenario unsupported discovery scope

session alice
connect
auth

query discover scope policy

expect error unsupported
```

- discovery scope може бути не підтриманий конкретною реалізацією
- unsupported discovery не змінює state

## DISC-9. Unknown discovery target

```text
scenario unknown discovery target

session alice
connect
auth

query discover scope feed target group:missing

expect error notFound
```

- unknown target resource може повертати `notFound`
- discovery target resolution не означає доступу до самого ресурсу
