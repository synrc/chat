# MSC-DSL-CORRESPONDENCE

Практичний довідник стабільних відповідностей DSL → MSC.

Цей файл не дублює [MSC-MAPPING-v2.md](./MSC-MAPPING-v2.md), а фіксує:
- сталі DSL → MSC відповідності;
- канонічні правила оформлення;
- фактично використані предикати;
- короткі шаблони для типових сценаріїв.

Підтримка актуальності:
- якщо з’являється новий шаблон DSL, його треба додати у таблицю;
- якщо використано новий предикат, його треба додати у список;
- якщо з’являється новий стабільний сценарій, його треба додати як шаблон;
- наявні правила не змінюються без явної потреби.

## 1. Стабільні відповідності DSL → MSC

| Шаблон DSL | MSC-подання | Примітки |
|---|---|---|
| `scenario name` | `msc Name; ... endmsc;` | Назва сценарію нормалізується до назви MSC-фрагмента |
| `session alice` | `instance Alice;` | Псевдонім сесії стає `instance` |
| `session bob1 as bob` | `instance Bob1;` | Семантика, прив’язана до користувача, лишається в примітках, якщо це важливо |
| `given ...` | `Preconditions:` block | Не перетворювати на потік повідомлень |
| `given message m1 was visible to bob before ban` | `Preconditions: - message m1 was visible to bob before ban` | Припущення про попередню видимість, а не похідне від потоку повідомлень |
| `connect` | `Alice -> Server : Connect()` | Якщо є явна межа сервера |
| `connect brokerA` | `Alice -> BrokerA : Connect()` | Підключення до явно заданого брокера у федеративному сценарії |
| `connect alice@example.com` | `Alice -> Server : Connect(alice@example.com)` | Конкретний транспортний або вхідний параметр лишається в позначці |
| `auth` | `Alice -> Server : Authenticate(...)` | Деталі auth лишаються в параметрах |
| `auth password "secret"` | `Alice -> Server : Authenticate(password="secret")` | Канонічно як явний auth-параметр |
| `auth resume` | `Alice -> Server : Authenticate(resume)` | `resume` оформлюється як варіант auth |
| `auth supportedVsn [v1, v2]` | `Alice -> Server : Authenticate(supportedVsn=[v1, v2])` | Параметр узгодження версії |
| `renew` | `Alice -> Server : RenewAccessToken()` | Дія перевипуску токена доступу |
| `revoke access token` | `Alice -> Server : RevokeAccessToken()` | Дія відкликання токена доступу |
| `disconnect` | `Alice -> Server : Disconnect()` | Дія на рівні сесії |
| `reconnect` | `Alice -> Server : Connect()` | Окреме повторне підключення |
| `send message to bob "hi"` | `Alice -> Server : SendMessage("hi")` + `Server -> Bob : DeliverMessage("hi")` | Канонічна доставка через сервер |
| `send message to bob@brokerB "hi"` | `Alice -> BrokerA : SendMessage(to=bob@brokerB, body="hi")` + broker routing | Маршрутизована доставка у федеративному сценарії |
| `send message to bob { ... }` | `Alice -> Server : SendMessage({...})` + `Server -> Bob : DeliverMessage({...})` | Структурований вміст лишається станом повідомлення |
| `send message to bob { body: "hi" mention: bob }` | `Alice -> Server : SendMessage({body="hi", mentions=[Bob]})` + `Server -> Bob : DeliverMessage({body="hi", mentions=[Bob]})` | Коротка форма DSL `mention: bob` є синтаксичним скороченням канонічних згадок у вмісті |
| `send message to bob { ... } capture id as doc1` | `Alice -> Server : SendMessage({...})` | Зафіксований псевдонім `id` лишається у примітках або локальній прив’язці, а не стає новою базовою MSC-конструкцією |
| `send typing to bob` | `Alice -> Server : SendTyping(Bob)` | Короткочасна дія присутності |
| `send message to group:room1 "g1"` | `Alice -> Server : SendGroupMessage(room1, "g1")` + delivery fanout | Для групової стрічки |
| `create group room1` | `Alice -> Server : CreateGroup(room1)` | Зміна ресурсу |
| `add bob to group room1` | `Alice -> Server : AddMember(room1, Bob)` | Зміна членства |
| `remove bob from group room1` | `Alice -> Server : RemoveMember(room1, Bob)` | Зміна членства |
| `delete group room1` | `Alice -> Server : DeleteGroup(room1)` | Видалення ресурсу |
| `ban bob` | `Alice -> Server : Ban(Bob)` | Глобальна зміна moderation-стану |
| `unban bob` | `Alice -> Server : Unban(Bob)` | Глобальна зміна moderation-стану |
| `ban bob in group room1` | `Alice -> Server : BanInGroup(room1, Bob)` | Зміна moderation-стану в межах групи |
| `unban bob in group room1` | `Alice -> Server : UnbanInGroup(room1, Bob)` | Зміна moderation-стану в межах групи |
| `add bob to roster` | `Alice -> Server : AddToRoster(Bob)` | Зміна зв’язку в roster |
| `remove bob from roster` | `Alice -> Server : RemoveFromRoster(Bob)` | Зміна зв’язку в roster |
| `query roster` | `Alice -> Server : RosterQuery()` | Запит до roster-подання |
| `query subscriptions` | `Alice -> Server : SubscriptionQuery()` | Запит до подання підписок |
| `query moderation` | `Alice -> Server : ModerationListQuery()` | Запит до глобального moderation-подання |
| `query moderation group room1` | `Alice -> Server : ModerationListQuery(group=room1)` | Запит до moderation-подання в межах групи |
| `when alice queries inbox` | `Alice -> Server : InboxQuery()` | Скорочення для запиту до inbox-подання в policy-сценаріях |
| `when alice sends message` | `Alice -> Server : SendMessage(...)` | Скорочення для контексту оцінювання команди в policy-сценаріях |
| `when alice queries events for group room1` | `Alice -> Server : EventQuery(group=room1)` | Скорочення для контексту оцінювання групового запиту в policy-сценаріях |
| `query discover server` | `Alice -> Server : DiscoverQuery(scope=server)` | Виявлення можливостей сервера |
| `query discover auth` | `Alice -> Server : DiscoverQuery(scope=auth)` | Виявлення auth-можливостей |
| `query discover extension` | `Alice -> Server : DiscoverQuery(scope=extension)` | Виявлення можливостей розширень |
| `query discover group chat1` | `Alice -> Server : DiscoverQuery(scope=feed, target=group:chat1)` | Скорочення для виявлення групи над явною ціллю стрічки |
| `query discover scope feed target group:chat1` | `Alice -> Server : DiscoverQuery(scope=feed, target=group:chat1)` | Явна форма виявлення з ціллю |
| `query discover scope policy` | `Alice -> Server : DiscoverQuery(scope=policy)` | Явна форма виявлення лише з областю |
| `query search text "draft"` | `Alice -> Server : SearchQuery(scope=all, text="draft")` | Глобальний текстовий пошуковий запит |
| `query search peer alice text "draft"` | `Bob -> Server : SearchQuery(scope=peer:alice, text="draft")` | Пошуковий запит у межах peer-області |
| `query search group room1 text "draft"` | `Bob -> Server : SearchQuery(scope=group:room1, text="draft")` | Пошуковий запит у межах групової області |
| `query search peer alice text "draft" limit 2` | `Bob -> Server : SearchQuery(scope=peer:alice, text="draft", limit=2)` | Обмежений пошуковий запит у межах peer-області |
| `query search continue` | `Bob -> Server : SearchQuery(continue)` | Продовження пошуку в поточному контексті запиту |
| `query search peer alice field body like "draft"` | `Bob -> Server : SearchQuery(scope=peer:alice, field=body, criteria=like, value="draft")` | Пошук за полем у межах peer-області |
| `query search peer alice field tag equal "release"` | `Bob -> Server : SearchQuery(scope=peer:alice, field=tag, criteria=equal, value="release")` | Точний пошук за полем у межах peer-області |
| `query search group room1 field tag equal "release"` | `Bob -> Server : SearchQuery(scope=group:room1, field=tag, criteria=equal, value="release")` | Точний пошук за полем у межах групової області |
| `query search peer alice field body like "draft" return body tag` | `Bob -> Server : SearchQuery(scope=peer:alice, field=body, criteria=like, value="draft", fields=[body, tag])` | Пошуковий запит із проєкцією |
| `query inbox peer alice` | `Bob -> Server : InboxQuery(peer=alice)` | Запит до історії або подання |
| `query inbox feed private:alice` | `Bob -> Server : InboxQuery(feed=private:alice)` | Запит до inbox-подання в межах стрічки |
| `query inbox group room1` | `Bob -> Server : InboxQuery(group=room1)` | Запит до групового inbox або групової стрічки |
| `query inbox peer alice limit 10` | `Bob -> Server : InboxQuery(peer=alice, limit=10)` | Обмежена inbox-сторінка |
| `query inbox continue` | `Bob -> Server : InboxQuery(continue)` | Продовження в поточному inbox-контексті |
| `query group room1` | `Alice -> Server : GroupQuery(room1)` | Запит до одного групового подання |
| `query groups` | `Alice -> Server : GroupListQuery()` | Запит до списку груп |
| `query members of group room1` | `Alice -> Server : MemberListQuery(room1)` | Запит до списку учасників групи |
| `query events peer alice after cursor` | `Bob -> Server : EventQuery(peer=alice, after=cursor)` | Канонічний replay query |
| `query events peer alice after snapshot` | `Bob -> Server : EventQuery(peer=alice, after=snapshot)` | Replay query from snapshot boundary |
| `query events peer alice after 0` | `Bob -> Server : EventQuery(peer=alice, after=0)` | Replay from start / baseline cursor |
| `query events peer alice after cursor limit 2` | `Bob -> Server : EventQuery(peer=alice, after=cursor, limit=2)` | Обмежений replay-запит |
| `query events peer alice after next` | `Bob -> Server : EventQuery(peer=alice, after=next)` | Продовження replay за поверненим курсором |
| `query events feed private:alice after 0` | `Bob -> Server : EventQuery(feed=private:alice, after=0)` | Replay у межах стрічки від початкового курсора |
| `query events feed private:alice after snapshot` | `Bob -> Server : EventQuery(feed=private:alice, after=snapshot)` | Replay у межах стрічки від межі знімка |
| `query events group room1 after cursor` | `Bob -> Server : EventQuery(group=room1, after=cursor)` | Replay-запит у межах групи |
| `query events group room1 after 0` | `Bob -> Server : EventQuery(group=room1, after=0)` | Replay у межах групи від початкового курсора |
| `query events group room1 after snapshot` | `Bob -> Server : EventQuery(group=room1, after=snapshot)` | Replay-запит у межах групи від знімка home |
| `bootstrap home` | `Bob -> Server : HomeQuery(...)` | Мінімальний запит початкового завантаження home |
| `bootstrap home limit 10 preview 1` | `Bob -> Server : HomeQuery(limit=10, preview=1)` | Запит початкового завантаження home |
| `query home continue` | `Bob -> Server : HomeQuery(continue)` | Продовження в поточному home-контексті |
| `query cursor read feed private:alice up to 2` | `Bob -> Server : ReadCursorQuery(feed=private:alice, up_to=2)` | Форма запиту до курсора читання |
| `query cursor read peer alice up to 2` | `Bob -> Server : ReadCursorQuery(feed=private:alice, up_to=2)` | Форма запиту до peer-курсора читання |
| `send read for last` | `Bob -> Server : UpdateReadCursor(feed=..., up_to=last_observed)` | Конкретне `up_to` виводиться з локально спостережуваної межі |
| `send read peer alice for last` | `Bob -> Server : UpdateReadCursor(feed=private:alice, up_to=last_observed)` | Оновлення peer-курсора читання |
| `send read group room1 for last` | `Bob -> Server : UpdateReadCursor(feed=group:room1, up_to=last_observed)` | Оновлення курсора читання в межах стрічки |
| `query cursor read group room1 up to 1` | `Bob -> Server : ReadCursorQuery(feed=group:room1, up_to=1)` | Форма запиту до групового курсора читання |
| `edit message "doc" field subject "Draft v2"` | `Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2")` | Field-level edit by local ref |
| `edit message ref "doc" field subject "Draft v2"` | `Alice -> Server : EditMessage(ref="doc", field=subject, value="Draft v2")` | Field-level edit by explicit ref |
| `edit message id doc1 field subject "Draft v2"` | `Alice -> Server : EditMessage(id=doc1, field=subject, value="Draft v2")` | Field-level edit by protocol identity |
| `delete message ref "doc"` | `Alice -> Server : DeleteMessage(ref="doc")` | Delete by local ref |
| `delete message id doc1` | `Alice -> Server : DeleteMessage(id=doc1)` | Delete by protocol identity |
| `expect message from alice body "hi"` | `condition Seen(Message(from=Alice, body="hi"));` | Перевірка на рівні спостереження в межах `instance`, що отримує або спостерігає |
| `expect message from alice { ... }` | `condition Seen(Message(from=Alice, ...));` | Структурована або часткова перевірка вмісту на рівні спостереження |
| `expect not message from alice { ... }` | `condition Seen(Message(from=Alice, ...)) = false;` | Негативна перевірка вмісту на рівні спостереження |
| `expect message marked as read` | `condition Seen(MessageEvent(read, actor=Bob, seq=N));` | Конкретне спостереження read-події в межах `instance`, що отримує або спостерігає, а не перевірка кінцевого стану |
| `expect event offline` | `condition Seen(PresenceEvent(offline));` | Спостереження присутності без явного актора |
| `expect event offline alice` | `condition Seen(PresenceEvent(offline, actor=Alice));` | Aggregate user-scoped offline fact |
| `expect event online alice` | `condition Seen(PresenceEvent(online, actor=Alice));` | Aggregate user-scoped online fact |
| `expect event typing alice` | `condition Seen(PresenceEvent(typing, actor=Alice));` | Короткочасне спостереження присутності |
| `expect event message read bob up to 1` | `condition Seen(MessageEvent(read, actor=Bob, up_to=1));` | Точно спостережена read-подія з явним актором |
| `expect event message read up to 1` | `condition Seen(MessageEvent(read, up_to=1));` | Точно спостережена read-подія з неявним актором |
| `expect event message deleted alice id m1id` | `condition Seen(MessageEvent(deleted, actor=Alice, id=m1id));` | Точно спостережена delete-подія за ідентичністю протоколу |
| `expect authenticated` | `condition Authenticated(Alice);` | Підсумок або стан auth, а не спостереження |
| `expect session created` | `condition SessionCreated(Alice);` | Первинний auth створив сесію |
| `expect same session` | `condition SameSession(Alice);` | `resume` або `renew` зберегли ідентичність сесії |
| `expect access token` | `condition AccessTokenIssued(Alice);` | Токен доступу видано для актора |
| `expect access token refreshed` | `condition AccessTokenIssued(Alice);` | Оновлений токен моделюється як підсумок видачі токена |
| `expect read cursor updated` | `condition FinalState(ReadCursor(...), up_to=N);` | Єдина форма для read cursor result semantics |
| `expect read cursor unchanged in private:alice` | `condition NotChanged(ReadCursor(actor=Bob, feed=private:alice));` | Для isolation / no side effect |
| `expect bob in roster` | `condition FinalState(Roster(actor=Alice), contains(Bob));` | Членство в roster як локальний для актора кінцевий стан подання |
| `expect bob not in roster` | `condition FinalState(Roster(actor=Alice), excludes(Bob));` | Негативна перевірка членства в roster як локальний для актора кінцевий стан подання |
| `expect bob is banned` | `condition FinalState(Moderation(scope=global), contains(Bob));` | Глобальний moderation-стан |
| `expect bob is banned in group room1` | `condition FinalState(Moderation(scope=group:room1), contains(Bob));` | moderation-стан у межах групи |
| `expect group room1 exists` | `condition FinalState(Group(room1), exists);` | Перевірка існування групи на рівні стану |
| `expect alice is owner of group room1` | `condition FinalState(GroupOwner(group=room1), Alice);` | Перевірка власника групи на рівні стану |
| `expect bob is member of group room1` | `condition FinalState(GroupMembers(group=room1), contains(Bob));` | Перевірка членства в групі на рівні стану |
| `expect groups` | `condition ResultNotEmpty;` | Перевірка непорожнього результату для подання списку груп |
| `expect room1 in groups` | `condition FinalState(GroupList(actor=Alice), contains(room1));` | Локальне для актора подання списку груп |
| `expect members` | `condition ResultNotEmpty;` | Перевірка непорожнього результату для подання списку учасників |
| `expect moderation` | `condition ResultNotEmpty;` | Перевірка непорожнього результату для moderation-подання |
| `expect bob in moderation` | `condition FinalState(Moderation(...), contains(Bob));` | Членство в moderation-списку в межах поточного контексту запиту |
| `expect subscriptions` | `condition ResultNotEmpty;` | Перевірка непорожнього результату для подання підписок |
| `expect bob in subscriptions` | `condition FinalState(Subscriptions(actor=Alice), contains(Bob));` | Локальне для актора подання підписок |
| `expect mentions` | `condition FinalState(Mentions(actor=Bob), present);` | Локальний для актора стан подання, похідний від згадок у home або стрічці |
| `expect not mentions` | `condition FinalState(Mentions(actor=Bob), absent);` | Відсутній локальний для актора стан подання, похідний від згадок |
| `expect access allowed` | `condition Permitted(action);` | Policy дозволяє поточну дію або запит |
| `expect access denied` | `condition Forbidden(action);` | Policy забороняє поточну дію або запит |
| `expect selectedVsn v2` | `condition FinalState(SessionVersion(actor=Alice), v2);` | Узгоджена версія сесії як кінцевий стан |
| `expect message m1 visible` | `condition Visible(m1);` | Видимість на рівні подання або policy |
| `expect message m1 hidden` | `condition Hidden(m1);` | Прихований стан на рівні подання або policy |
| `expect message m1 field body visible` | `condition FieldVisible(m1, body);` | Field-level visibility |
| `expect message m1 field attachment hidden` | `condition FieldHidden(m1, attachment);` | Field-level hidden state |
| `expect feature protocol.version` | `condition HasFeature(protocol.version);` | Перевірка включення можливості у discovery-результат |
| `expect search shows message m1` | `condition SearchShows(m1);` | Пошуковий результат містить елемент |
| `expect search hides message m1` | `condition SearchHides(m1);` | Пошуковий результат не відкриває елемент |
| `expect message deleted` | `condition FinalState(Message(...), deleted);` | Стан життєвого циклу повідомлення з поточного контексту видалення |
| `expect events` | `condition ResultNotEmpty;` | Перевірка на рівні результату, а не спостереження |
| `expect events non-empty` | `condition ResultNotEmpty;` | Те саме |
| `expect events count <= N` | `condition ResultCount <= N;` | Для bounded replay/page results |
| `expect result items` | `condition ResultNotEmpty;` | Перевірка непорожнього набору елементів сторінки |
| `expect result items <= N` | `condition ResultCount <= N;` | Обмежений результат сторінки |
| `expect result items = 0` | `condition ResultCount = 0;` | Порожній результат сторінки |
| `expect messages` | `condition ResultNotEmpty;` | Перевірка на рівні результату для подання або історії, а не на рівні спостереження |
| `expect feeds` | `condition ResultNotEmpty;` | Перевірка непорожнього результату для сторінки home-стрічки |
| `expect feeds count <= N` | `condition ResultCount <= N;` | Обмежений результат сторінки home-стрічки |
| `expect feeds count = 0` | `condition ResultCount = 0;` | Порожній результат сторінки home-стрічки |
| `expect more` | `condition HasMore;` | Продовження розбиття на сторінки або replay |
| `expect next` | `condition HasNext;` | Курсор продовження присутній |
| `expect not more` | `condition HasMore = false;` | Негативна форма без нового предиката |
| `expect shared snapshot` | `condition HasSnapshot;` | Присутня спільна межа знімка |
| `expect snapshot` | `condition HasSnapshot;` | Присутня межа знімка |
| `expect empty replay` | `condition ReplayEmpty;` | Replay-результат порожній |
| `expect error badRequest` | `condition Error(badRequest);` | Result error |
| `expect error gap` | `condition Error(gap);` | Replay failed due to missing recovery boundary |
| `expect error forbidden` | `condition Error(forbidden);` | Result error |
| `expect error notFound` | `condition Error(notFound);` | Result error |
| `expect not error forbidden` | `condition Permitted(action);` | Дія або запит дозволені за поточного policy-стану |
| `expect no gaps` | `condition NoGaps;` | Replay continuity |
| `expect no duplicates` | `condition NoDuplicates;` | Replay overlap check |
| `expect not duplicate feeds` | `condition NoDuplicates;` | No repeated feed entries across paged home result |

## 2. Канонічні rules

### 2.1. Загальні правила

- Спочатку використовувати базові MSC-конструкції: `instance`, arrows, `loop`, `alt`, `opt`, `condition`.
- `given` завжди оформлюється як `Preconditions:`, а не як flow.
- `expect` ніколи не перетворюється на action.
- Якщо сценарій проходить через сервер, використовувати явний `instance Server`.

### 2.2. Результат vs спостереження

- Result-level перевірки оформлюються через `condition ResultNotEmpty`, `HasMore`, `ReplayEmpty`, `Error(...)`, `FinalState(...)`.
- Observation-level перевірки оформлюються тільки через `condition Seen(...)`.
- У search-сценаріях `expect message ...` може оформлюватися як `condition SearchShows(Message(...));`, а не як `Seen(...)`, якщо перевіряється включення в search-результат.
- `Seen(...)` трактується у scope receiving / observing instance; якщо receiving side неявна, цей scope вважається implicit from scenario context.
- Не використовувати `Seen(...)` для позначення просто факту наявності result.
- Search-рівневе `expect result items` у MSC нормалізується до `condition ResultNotEmpty;`.

### 2.3. Курсор читання

- `expect read cursor updated` завжди оформлюється тільки як `condition FinalState(ReadCursor(...), up_to=...)`.
- `expect message marked as read` лишається observation-level перевіркою через `Seen(MessageEvent(read, ...))`.
- Для семантики ізоляції використовувати `NotChanged(ReadCursor(...))`.

### 2.4. Неперервність auth

- `reconnect` саме по собі означає лише нове транспортне з’єднання і не додає окремого auth-предиката.
- Якщо сценарій після `reconnect` одразу виконує protected action і очікує `Permitted(action)`, це фіксує, що валідний auth context збережено через reconnect.
- `auth resume` є явним необов’язковим шляхом відновлення і використовується тоді, коли сценарій хоче явно перевірити відновлення наявної сесії.
- `renew` моделюється як action у вже валідному session/auth context; після `reconnect` воно використовується як шлях неперервності сесії, а не як створення нової сесії.

### 2.5. Replay і розбиття на сторінки

- Для replay у read-сценаріях можна використовувати `MessageEvent(...)` усередині replay-циклу.
- `MessageEvent(...)` у replay-шаблоні є прикладом для read-орієнтованих сценаріїв, а не універсальним типом події для всіх випадків replay.
- Бажана назва циклу: `replay_events`.
- Якщо replay/query bounded by `limit`, додавати `condition ResultCount <= N;`.
- `expect more` / `expect not more` відображаються через `HasMore` / `HasMore = false`.

### 2.6. Назви та стиль

- Назви предикатів мають бути однаковими по всьому корпусу.
- `FinalState(...)` має використовуватись в одній формі без варіантів на кшталт cursor-updated event predicates.
- `Roster(actor=X)` завжди означає локальне для актора roster-подання користувача `X`, а не глобальний або спільний об’єкт зв’язку.
- `GroupList(actor=X)` завжди означає локальне для актора подання списку груп користувача `X`.
- `Subscriptions(actor=X)` завжди означає локальне для актора подання підписок користувача `X`.
- `Moderation(scope=global)` і `Moderation(scope=group:<name>)` означають policy-стан у відповідній області.
- `Mentions(actor=X)` означає локальний для актора стан подання, похідний від згадок, а не окремий protocol-об’єкт.
- `Extensions used` містить тільки реально використані предикати без дублювання.

## 3. Predicates in Use

### Спостереження

- `Seen(Message(...))`
- `Seen(MessageEvent(...))`
- `Seen(PresenceEvent(...))`

### Результат / Replay

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

### Кінцевий стан / Узгодженість

- `FinalState(target, state)`
- `NotChanged(target)`

### Інші зафіксовані в mapping предикати

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
- `MessageEvent(...)` тут показано як read-орієнтований приклад replay; для інших предметних сценаріїв конкретний тип події може відрізнятись.

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
