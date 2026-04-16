# MSC-DSL-CORRESPONDENCE

Практичний довідник стабільних відповідностей DSL → MSC.

Цей файл не дублює [MSC-MAPPING-v2.md](./MSC-MAPPING-v2.md), а фіксує:
- сталі DSL → MSC відповідності;
- канонічні правила оформлення;
- фактично використані predicates;
- короткі шаблони для типових сценаріїв.

Підтримка актуальності:
- якщо з’являється новий DSL pattern, його треба додати у таблицю;
- якщо використано новий predicate, його треба додати у список;
- якщо з’являється новий стабільний сценарій, його треба додати як шаблон;
- існуючі rules не змінюються без явної потреби.

## 1. Стабільні відповідності DSL → MSC

| DSL pattern | MSC form | Notes |
|---|---|---|
| `scenario name` | `msc Name; ... endmsc;` | Назва сценарію нормалізується до MSC fragment name |
| `session alice` | `instance Alice;` | Session alias стає instance |
| `session bob1 as bob` | `instance Bob1;` | User-scoped semantics лишається в Notes, якщо це важливо |
| `given ...` | `Preconditions:` block | Не перетворювати у message flow |
| `given message m1 was visible to bob before ban` | `Preconditions: - message m1 was visible to bob before ban` | Historical visibility assumption, not derived from message flow |
| `connect` | `Alice -> Server : Connect()` | Якщо є explicit server boundary |
| `connect brokerA` | `Alice -> BrokerA : Connect()` | Federation-aware connect to explicit broker instance |
| `connect alice@example.com` | `Alice -> Server : Connect(alice@example.com)` | Конкретний transport/login payload лишається в label |
| `auth` | `Alice -> Server : Authenticate(...)` | Деталі auth лишаються в параметрах |
| `auth password "secret"` | `Alice -> Server : Authenticate(password="secret")` | Канонічно як explicit auth payload |
| `auth resume` | `Alice -> Server : Authenticate(resume)` | Resume оформлюється як auth variant |
| `auth supportedVsn [v1, v2]` | `Alice -> Server : Authenticate(supportedVsn=[v1, v2])` | Version negotiation payload |
| `renew` | `Alice -> Server : RenewAccessToken()` | Access token renewal action |
| `revoke access token` | `Alice -> Server : RevokeAccessToken()` | Access token revocation action |
| `disconnect` | `Alice -> Server : Disconnect()` | Session-level дія |
| `reconnect` | `Alice -> Server : Connect()` | Окреме повторне підключення |
| `send message to bob "hi"` | `Alice -> Server : SendMessage("hi")` + `Server -> Bob : DeliverMessage("hi")` | Канонічна server-mediated delivery |
| `send message to bob@brokerB "hi"` | `Alice -> BrokerA : SendMessage(to=bob@brokerB, body="hi")` + broker routing | Federation-aware routed delivery |
| `send message to bob { ... }` | `Alice -> Server : SendMessage({...})` + `Server -> Bob : DeliverMessage({...})` | Structured payload is still message-level state |
| `send message to bob { body: "hi" mention: bob }` | `Alice -> Server : SendMessage({body="hi", mentions=[Bob]})` + `Server -> Bob : DeliverMessage({body="hi", mentions=[Bob]})` | DSL short form `mention: bob` is sugar over canonical payload mentions |
| `send message to bob { ... } capture id as doc1` | `Alice -> Server : SendMessage({...})` | Captured id alias is recorded in Notes / local binding, not a new MSC core construct |
| `send typing to bob` | `Alice -> Server : SendTyping(Bob)` | Transient presence action |
| `send message to group:room1 "g1"` | `Alice -> Server : SendGroupMessage(room1, "g1")` + delivery fanout | Для group feed |
| `create group room1` | `Alice -> Server : CreateGroup(room1)` | Resource mutation |
| `add bob to group room1` | `Alice -> Server : AddMember(room1, Bob)` | Membership mutation |
| `remove bob from group room1` | `Alice -> Server : RemoveMember(room1, Bob)` | Membership mutation |
| `delete group room1` | `Alice -> Server : DeleteGroup(room1)` | Resource deletion |
| `ban bob` | `Alice -> Server : Ban(Bob)` | Global moderation mutation |
| `unban bob` | `Alice -> Server : Unban(Bob)` | Global moderation mutation |
| `ban bob in group room1` | `Alice -> Server : BanInGroup(room1, Bob)` | Group-scoped moderation mutation |
| `unban bob in group room1` | `Alice -> Server : UnbanInGroup(room1, Bob)` | Group-scoped moderation mutation |
| `add bob to roster` | `Alice -> Server : AddToRoster(Bob)` | Roster relation mutation |
| `remove bob from roster` | `Alice -> Server : RemoveFromRoster(Bob)` | Roster relation mutation |
| `query roster` | `Alice -> Server : RosterQuery()` | Roster view query |
| `query subscriptions` | `Alice -> Server : SubscriptionQuery()` | Subscription view query |
| `query moderation` | `Alice -> Server : ModerationListQuery()` | Global moderation view query |
| `query moderation group room1` | `Alice -> Server : ModerationListQuery(group=room1)` | Group-scoped moderation view query |
| `when alice queries inbox` | `Alice -> Server : InboxQuery()` | Shorthand for inbox view query in policy/view scenarios |
| `when alice sends message` | `Alice -> Server : SendMessage(...)` | Shorthand for command evaluation context in policy scenarios |
| `when alice queries events for group room1` | `Alice -> Server : EventQuery(group=room1)` | Shorthand for group query evaluation context in policy scenarios |
| `query discover server` | `Alice -> Server : DiscoverQuery(scope=server)` | Server capability discovery |
| `query discover auth` | `Alice -> Server : DiscoverQuery(scope=auth)` | Auth capability discovery |
| `query discover extension` | `Alice -> Server : DiscoverQuery(scope=extension)` | Extension capability discovery |
| `query discover group chat1` | `Alice -> Server : DiscoverQuery(scope=feed, target=group:chat1)` | Group discovery sugar over explicit feed target |
| `query discover scope feed target group:chat1` | `Alice -> Server : DiscoverQuery(scope=feed, target=group:chat1)` | Explicit discovery form with target |
| `query discover scope policy` | `Alice -> Server : DiscoverQuery(scope=policy)` | Explicit discovery form with scope only |
| `query search text "draft"` | `Alice -> Server : SearchQuery(scope=all, text="draft")` | Global text search query |
| `query search peer alice text "draft"` | `Bob -> Server : SearchQuery(scope=peer:alice, text="draft")` | Peer-scoped text search query |
| `query search group room1 text "draft"` | `Bob -> Server : SearchQuery(scope=group:room1, text="draft")` | Group-scoped text search query |
| `query search peer alice text "draft" limit 2` | `Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2)` | Bounded peer-scoped text search query |
| `query search continue` | `Bob -> Server : SearchQuery(continue)` | Search continuation in current query context |
| `query search peer alice field body like "draft"` | `Bob -> Server : SearchQuery(scope=peer:alice, field=body, criteria=like, value="draft")` | Peer-scoped field search |
| `query search peer alice field tag equal "release"` | `Bob -> Server : SearchQuery(scope=peer:alice, field=tag, criteria=equal, value="release")` | Peer-scoped exact field search |
| `query search group room1 field tag equal "release"` | `Bob -> Server : SearchQuery(scope=group:room1, field=tag, criteria=equal, value="release")` | Group-scoped exact field search |
| `query search peer alice field body like "draft" return body tag` | `Bob -> Server : SearchQuery(scope=peer:alice, field=body, criteria=like, value="draft", fields=[body, tag])` | Search projection query |
| `query inbox peer alice` | `Bob -> Server : InboxQuery(peer=alice)` | History/view query |
| `query inbox feed private:alice` | `Bob -> Server : InboxQuery(feed=private:alice)` | Feed-scoped inbox query |
| `query inbox group room1` | `Bob -> Server : InboxQuery(group=room1)` | Group inbox / group feed view query |
| `query inbox peer alice limit 10` | `Bob -> Server : InboxQuery(peer=alice, limit=10)` | Bounded inbox page |
| `query inbox continue` | `Bob -> Server : InboxQuery(continue)` | Continuation in current inbox query context |
| `query group room1` | `Alice -> Server : GroupQuery(room1)` | Single group view query |
| `query groups` | `Alice -> Server : GroupListQuery()` | Group list view query |
| `query members of group room1` | `Alice -> Server : MemberListQuery(room1)` | Group member list view query |
| `query events peer alice after cursor` | `Bob -> Server : EventQuery(peer=alice, after=cursor)` | Канонічний replay query |
| `query events peer alice after snapshot` | `Bob -> Server : EventQuery(peer=alice, after=snapshot)` | Replay query from snapshot boundary |
| `query events peer alice after 0` | `Bob -> Server : EventQuery(peer=alice, after=0)` | Replay from start / baseline cursor |
| `query events peer alice after cursor limit 2` | `Bob -> Server : EventQuery(peer=alice, after=cursor, limit=2)` | Bounded replay |
| `query events peer alice after next` | `Bob -> Server : EventQuery(peer=alice, after=next)` | Replay continuation by returned cursor |
| `query events feed private:alice after 0` | `Bob -> Server : EventQuery(feed=private:alice, after=0)` | Feed-scoped replay from baseline cursor |
| `query events feed private:alice after snapshot` | `Bob -> Server : EventQuery(feed=private:alice, after=snapshot)` | Feed-scoped replay from snapshot boundary |
| `query events group room1 after cursor` | `Bob -> Server : EventQuery(group=room1, after=cursor)` | Group-scoped replay query |
| `query events group room1 after 0` | `Bob -> Server : EventQuery(group=room1, after=0)` | Group-scoped replay from baseline cursor |
| `query events group room1 after snapshot` | `Bob -> Server : EventQuery(group=room1, after=snapshot)` | Group-scoped replay query from home snapshot |
| `bootstrap home` | `Bob -> Server : HomeQuery(...)` | Minimal home bootstrap query |
| `bootstrap home limit 10 preview 1` | `Bob -> Server : HomeQuery(limit=10, preview=1)` | Home bootstrap query |
| `query home continue` | `Bob -> Server : HomeQuery(continue)` | Continuation in current home query context |
| `query cursor read feed private:alice up to 2` | `Bob -> Server : ReadCursorQuery(feed=private:alice, up_to=2)` | Read cursor query form |
| `query cursor read peer alice up to 2` | `Bob -> Server : ReadCursorQuery(feed=private:alice, up_to=2)` | Peer-scoped read cursor query form |
| `send read for last` | `Bob -> Server : UpdateReadCursor(feed=..., up_to=last_observed)` | Конкретне `up_to` виводиться з локально observed boundary |
| `send read peer alice for last` | `Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=last_observed)` | Peer-scoped read update |
| `send read group room1 for last` | `Bob -> Server : UpdateReadCursor(feed=group:room1, up_to=last_observed)` | Feed-scoped read update |
| `query cursor read group room1 up to 1` | `Bob -> Server : ReadCursorQuery(feed=group:room1, up_to=1)` | Group-scoped read cursor query form |
| `edit message "doc" field subject "Draft v2"` | `Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2")` | Field-level edit by local ref |
| `edit message ref "doc" field subject "Draft v2"` | `Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2")` | Field-level edit by explicit ref |
| `edit message id doc1 field subject "Draft v2"` | `Alice -> Server : EditMessage(id=doc1, field=subject, value="Draft v2")` | Field-level edit by protocol identity |
| `delete message ref "doc"` | `Alice -> Server : DeleteMessage(ref="doc")` | Delete by local ref |
| `delete message id doc1` | `Alice -> Server : DeleteMessage(id=doc1)` | Delete by protocol identity |
| `expect message from alice body "hi"` | `condition Seen(Message(from=Alice, body="hi"));` | Observation-level check in the receiving instance scope |
| `expect message from alice { ... }` | `condition Seen(Message(from=Alice, ...));` | Structured or partial payload match at message observation level |
| `expect not message from alice { ... }` | `condition Seen(Message(from=Alice, ...)) = false;` | Negative payload observation match |
| `expect message marked as read` | `condition Seen(MessageEvent(read, actor=Bob, seq=N));` | Конкретна read observation у receiving / observing instance scope, не final-state check |
| `expect event offline` | `condition Seen(PresenceEvent(offline));` | Presence observation without explicit actor |
| `expect event offline alice` | `condition Seen(PresenceEvent(offline, actor=Alice));` | Aggregate user-scoped offline fact |
| `expect event online alice` | `condition Seen(PresenceEvent(online, actor=Alice));` | Aggregate user-scoped online fact |
| `expect event typing alice` | `condition Seen(PresenceEvent(typing, actor=Alice));` | Transient presence observation |
| `expect event message read bob up to 1` | `condition Seen(MessageEvent(read, actor=Bob, up_to=1));` | Exact observed read event with explicit actor |
| `expect event message read up to 1` | `condition Seen(MessageEvent(read, up_to=1));` | Exact observed read event with wildcard actor |
| `expect event message deleted alice id m1id` | `condition Seen(MessageEvent(deleted, actor=Alice, id=m1id));` | Exact observed delete event by protocol identity |
| `expect authenticated` | `condition Authenticated(Alice);` | Auth result/state, not observation |
| `expect session created` | `condition SessionCreated(Alice);` | Primary auth created a session |
| `expect same session` | `condition SameSession(Alice);` | Resume/renew preserved session identity |
| `expect access token` | `condition AccessTokenIssued(Alice);` | Access token issued for the actor |
| `expect access token refreshed` | `condition AccessTokenIssued(Alice);` | Refreshed token is modeled as token issuance result |
| `expect read cursor updated` | `condition FinalState(ReadCursor(...), up_to=N);` | Єдина форма для read cursor result semantics |
| `expect read cursor unchanged in private:alice` | `condition NotChanged(ReadCursor(actor=Bob, feed=private:alice));` | Для isolation / no side effect |
| `expect bob in roster` | `condition FinalState(Roster(actor=Alice), contains(Bob));` | Roster membership as actor-local final view state |
| `expect bob not in roster` | `condition FinalState(Roster(actor=Alice), excludes(Bob));` | Negative roster membership as actor-local final view state |
| `expect bob is banned` | `condition FinalState(Moderation(scope=global), contains(Bob));` | Global moderation state |
| `expect bob is banned in group room1` | `condition FinalState(Moderation(scope=group:room1), contains(Bob));` | Group-scoped moderation state |
| `expect group room1 exists` | `condition FinalState(Group(room1), exists);` | Group existence as state-level check |
| `expect alice is owner of group room1` | `condition FinalState(GroupOwner(group=room1), Alice);` | Group owner as state-level check |
| `expect bob is member of group room1` | `condition FinalState(GroupMembers(group=room1), contains(Bob));` | Group membership as state-level check |
| `expect groups` | `condition ResultNotEmpty;` | Result-level check for group list view |
| `expect room1 in groups` | `condition FinalState(GroupList(actor=Alice), contains(room1));` | Actor-local group list view |
| `expect members` | `condition ResultNotEmpty;` | Result-level check for member list view |
| `expect moderation` | `condition ResultNotEmpty;` | Result-level check for moderation list view |
| `expect bob in moderation` | `condition FinalState(Moderation(...), contains(Bob));` | Moderation list membership in current query scope |
| `expect subscriptions` | `condition ResultNotEmpty;` | Result-level check for subscription list view |
| `expect bob in subscriptions` | `condition FinalState(Subscriptions(actor=Alice), contains(Bob));` | Actor-local subscriptions view |
| `expect mentions` | `condition FinalState(Mentions(actor=Bob), present);` | Mention-derived home/feed state is present for the actor |
| `expect not mentions` | `condition FinalState(Mentions(actor=Bob), absent);` | Mention-derived home/feed state is absent for the actor |
| `expect access allowed` | `condition Permitted(action);` | Policy allows the current query/action |
| `expect access denied` | `condition Forbidden(action);` | Policy denies the current query/action |
| `expect selectedVsn v2` | `condition FinalState(SessionVersion(actor=Alice), v2);` | Negotiated session version as final session state |
| `expect message m1 visible` | `condition Visible(m1);` | View/policy-level visibility |
| `expect message m1 hidden` | `condition Hidden(m1);` | View/policy-level hidden state |
| `expect message m1 field body visible` | `condition FieldVisible(m1, body);` | Field-level visibility |
| `expect message m1 field attachment hidden` | `condition FieldHidden(m1, attachment);` | Field-level hidden state |
| `expect feature protocol.version` | `condition HasFeature(protocol.version);` | Discovery feature inclusion check |
| `expect search shows message m1` | `condition SearchShows(m1);` | Search result contains the item |
| `expect search hides message m1` | `condition SearchHides(m1);` | Search result does not expose the item |
| `expect message deleted` | `condition FinalState(Message(...), deleted);` | Message lifecycle state from current delete context |
| `expect events` | `condition ResultNotEmpty;` | Result-level check, не observation |
| `expect events non-empty` | `condition ResultNotEmpty;` | Те саме |
| `expect events count <= N` | `condition ResultCount <= N;` | Для bounded replay/page results |
| `expect result items` | `condition ResultNotEmpty;` | Result-level check for paged item set |
| `expect result items <= N` | `condition ResultCount <= N;` | Bounded page result |
| `expect result items = 0` | `condition ResultCount = 0;` | Empty page result |
| `expect messages` | `condition ResultNotEmpty;` | Result-level перевірка для view/history result, не observation-level check |
| `expect feeds` | `condition ResultNotEmpty;` | Result-level check for home feed page |
| `expect feeds count <= N` | `condition ResultCount <= N;` | Bounded home feed page |
| `expect feeds count = 0` | `condition ResultCount = 0;` | Empty home feed page |
| `expect more` | `condition HasMore;` | Pagination / replay continuation |
| `expect next` | `condition HasNext;` | Continuation cursor is present |
| `expect not more` | `condition HasMore = false;` | Негативна форма без нового predicate |
| `expect shared snapshot` | `condition HasSnapshot;` | Shared snapshot anchor is present |
| `expect snapshot` | `condition HasSnapshot;` | Snapshot anchor is present |
| `expect empty replay` | `condition ReplayEmpty;` | Replay result is empty |
| `expect error badRequest` | `condition Error(badRequest);` | Result error |
| `expect error gap` | `condition Error(gap);` | Replay failed due to missing recovery boundary |
| `expect error forbidden` | `condition Error(forbidden);` | Result error |
| `expect error notFound` | `condition Error(notFound);` | Result error |
| `expect not error forbidden` | `condition Permitted(action);` | Action/query is permitted under current policy state |
| `expect no gaps` | `condition NoGaps;` | Replay continuity |
| `expect no duplicates` | `condition NoDuplicates;` | Replay overlap check |
| `expect not duplicate feeds` | `condition NoDuplicates;` | No repeated feed entries across paged home result |

## 2. Канонічні rules

### 2.1. General

- Використовувати MSC core спочатку: `instance`, arrows, `loop`, `alt`, `opt`, `condition`.
- `given` завжди оформлюється як `Preconditions:`, а не як flow.
- `expect` ніколи не перетворюється на action.
- Якщо сценарій server-mediated, використовувати явний `instance Server`.

### 2.2. Result vs Observation

- Result-level перевірки оформлюються через `condition ResultNotEmpty`, `HasMore`, `ReplayEmpty`, `Error(...)`, `FinalState(...)`.
- Observation-level перевірки оформлюються тільки через `condition Seen(...)`.
- У search scenarios `expect message ...` може оформлюватися як `condition SearchShows(Message(...));`, а не як `Seen(...)`, якщо перевіряється inclusion у search result.
- `Seen(...)` трактується у scope receiving / observing instance; якщо receiving side неявна, цей scope вважається implicit from scenario context.
- Не використовувати `Seen(...)` для позначення просто факту наявності result.
- Search-level `expect result items` у MSC нормалізується до `condition ResultNotEmpty;`.

### 2.3. Read cursor

- `expect read cursor updated` завжди оформлюється тільки як `condition FinalState(ReadCursor(...), up_to=...)`.
- `expect message marked as read` лишається observation-level перевіркою через `Seen(MessageEvent(read, ...))`.
- Для isolation semantics використовувати `NotChanged(ReadCursor(...))`.

### 2.4. Auth continuity

- `reconnect` саме по собі означає лише нове transport connection і не додає окремого auth predicate.
- Якщо сценарій після `reconnect` одразу виконує protected action і очікує `Permitted(action)`, це фіксує, що валідний auth context збережено через reconnect.
- `auth resume` є explicit optional restoration flow і використовується тоді, коли сценарій хоче явно перевірити відновлення існуючої session.
- `renew` моделюється як action у вже валідному session/auth context; після `reconnect` воно використовується як session-continuity flow, а не як створення нової session.

### 2.5. Replay and Pagination

- Для replay у read-сценаріях можна використовувати `MessageEvent(...)` усередині replay loop.
- `MessageEvent(...)` у replay template є прикладом для read-oriented scenarios, а не універсальним event type для всіх replay cases.
- Бажана назва loop: `replay_events`.
- Якщо replay/query bounded by `limit`, додавати `condition ResultCount <= N;`.
- `expect more` / `expect not more` відображаються через `HasMore` / `HasMore = false`.

### 2.6. Naming and Style

- Назви predicates мають бути однаковими по всьому корпусу.
- `FinalState(...)` має використовуватись в одній формі без варіантів на кшталт cursor-updated event predicates.
- `Roster(actor=X)` завжди означає actor-local roster view користувача `X`, а не global/shared relation object.
- `GroupList(actor=X)` завжди означає actor-local groups view користувача `X`.
- `Subscriptions(actor=X)` завжди означає actor-local subscriptions view користувача `X`.
- `Moderation(scope=global)` і `Moderation(scope=group:<name>)` означають policy state у відповідному scope.
- `Mentions(actor=X)` означає actor-local mention-derived view state, а не окремий protocol object.
- `Extensions used` містить тільки реально використані predicates без дублювання.

## 3. Predicates in Use

### Observation

- `Seen(Message(...))`
- `Seen(MessageEvent(...))`
- `Seen(PresenceEvent(...))`

### Result / Replay

- `ResultNotEmpty`
- `ResultCount relation`
- `HasMore`
- `ReplayEmpty`
- `Error(code)`
- `NoGaps`
- `NoDuplicates`
- `HasSnapshot`
- `Permitted(action)`
- `Forbidden(action)`

### Final-state / Consistency

- `FinalState(target, state)`
- `NotChanged(target)`

### Other documented predicates from mapping

- `Authenticated(actor)`
- `SessionCreated(x)`
- `SameSession(actor)`
- `AccessTokenIssued(actor)`
- `Visible(x)`
- `Hidden(x)`
- `FieldVisible(x, field)`
- `FieldHidden(x, field)`
- `HasFeature(id)`
- `SearchShows(x)`
- `SearchHides(x)`
- `ProjectionPreserved`

## 4. Short Templates

### 4.1. Delivery

**DSL**

```text
session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "hi"

session bob
expect message from alice body "hi"
```

**MSC**

```text
msc MessageDelivery;
  instance Alice;
  instance Server;
  instance Bob;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Alice -> Server : SendMessage("hi");
  Server -> Bob : DeliverMessage("hi");

  condition Seen(Message(from=Alice, body="hi"));
endmsc;
```

### 4.2. Read

**DSL**

```text
session bob
send read for last

expect read cursor updated
```

**MSC**

```text
msc ReadUpdate;
  instance Bob;
  instance Server;

  Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=2);

  condition FinalState(ReadCursor(actor=Bob, feed=private:alice), up_to=2);
endmsc;
```

### 4.3. Replay

**DSL**

```text
query events peer alice after cursor

expect events
```

**MSC**

```text
msc ReplayQuery;
  instance Bob;
  instance Server;

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultNotEmpty;
endmsc;
```

Примітка:
- `MessageEvent(...)` тут показано як read-oriented replay example; для інших domain scenarios конкретний event type може відрізнятись.

### 4.4. Roster Membership

**DSL**

```text
session alice
connect
auth

add bob to roster

query roster

expect bob in roster
```

**MSC**

```text
msc AddToRoster;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : AddToRoster(Bob);
  Alice -> Server : RosterQuery();

  condition FinalState(Roster(actor=Alice), contains(Bob));
endmsc;
```

Примітка:
- `Roster(actor=Alice)` означає локальний roster view Alice.

### 4.5. Pagination / Bounded Replay

**DSL**

```text
query events peer alice after cursor limit 1

expect events count <= 1
expect more
```

**MSC**

```text
msc ReplayPage;
  instance Bob;
  instance Server;

  Bob -> Server : EventQuery(peer=alice, after=cursor, limit=1);
  loop replay_events
    Server -> Bob : MessageEvent(...);
  endloop;

  condition ResultCount <= 1;
  condition ResultNotEmpty;
  condition HasMore;
endmsc;
```

### 4.6. Continue Query

**DSL**

```text
query inbox continue
```

**MSC**

```text
msc InboxContinue;
  instance Bob;
  instance Server;

  Bob -> Server : InboxQuery(continue);
endmsc;
```
