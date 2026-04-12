> See DSL-CORE.md for language definition

# DSL-HOME

Сценарії для home bootstrap, previews у feed, shared snapshot і взаємодії з policy

Цей файл описує view semantics для home/bootstrap layer:

- unread/view boundary
- preview
- snapshot
- replay boundary
- interaction з read semantics
- interaction з access policy

---

## HOME-1. Home returns feeds and snapshot after new message
```
scenario home returns feeds and snapshot after new message

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
bootstrap home

expect feeds
expect shared snapshot
expect feeds count <= 10
```

- home має повертати feed view і shared snapshot
- нове повідомлення має робити feed видимим у home

---

## HOME-2. Read does not break home bootstrap
```
scenario read does not break home bootstrap

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
query inbox peer alice
session bob
send read peer alice for last

session bob
bootstrap home

expect feeds
expect shared snapshot
```

- read змінює cursor state
- home після read лишається валідним bootstrap view

---

## HOME-3. Replay does not replace home snapshot
```
scenario replay does not replace home snapshot

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
query events peer alice after cursor

session bob
bootstrap home

expect feeds
expect shared snapshot
```

- replay/history view не замінює home bootstrap
- home snapshot залишається окремим view resource

---

## HOME-4. Home snapshot then replay preserves boundary
```
scenario home snapshot then replay preserves boundary

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "m1"

session bob
bootstrap home

session alice
send message to bob "m2"

session bob
query events peer alice after snapshot

expect events
expect no duplicates
expect no gaps
```

- shared snapshot з home має бути валідною boundary для replay
- replay після snapshot не повинен повертати вже покриті items

---

## HOME-5. Policy hides message from inbox-derived visibility
```
scenario policy hides message from inbox-derived visibility

given
message m1 has classification topsecret
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

- view filtering має бути узгодженим для inbox/home layer
- policy visibility не повинна ламати protocol truth

---

## HOME-6. Home snapshot does not bypass later group moderation
```
scenario home snapshot does not bypass later group moderation

session alice
connect
auth

create group room1
add bob to group room1

session bob
connect
auth

session bob
bootstrap home

session alice
ban bob in group room1

session bob
query events group room1 after snapshot

expect error forbidden
```

- home snapshot не гарантує доступ після зміни policy
- access check виконується на момент replay query
