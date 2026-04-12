> See DSL-CORE.md for language definition

# DSL-MENTIONS

Mention-derived view semantics у home, feed і unread model

Цей файл описує mention-derived view semantics:

- mention state у home/feed view
- relation між mention і unread
- relation між mention і read cursor
- relation між mention і visibility/policy

На цьому етапі mention у DSL трактується як view-derived state,
а не як окремий protocol object.

Для явної сценарної форми використовується structured payload field:

- `mention: <user>`

Це мінімальна explicit form для mention-carrying message.

Примітка:

- exact payload mapping для multiple mentions може бути розширена пізніше
- на цьому етапі важлива саме semantics, а не остаточний wire form

## Mention surface (minimal)

Mention у DSL є derived view semantics, а не окремим object/state type.

На цьому етапі:

- mention виникає з visible message payload
- mention є user-scoped
- mention є feed-scoped
- mention належить до view layer
- mention не створює окремий Event
- mention не змінює Message state
- mention не означає read
- replay сам по собі не очищає mention state

Mention вважається active only if:

- повідомлення видиме для user
- повідомлення входить до unread boundary
- payload містить explicit mention цього user

Цей шар фіксує:

- relation між mention і unread
- relation між mention і read cursor
- relation між mention і visibility/policy
- relation між mention і home/feed view

Цей шар поки не фіксує:

- multiple mentions encoding
- mention ranking/priorities
- mention-specific events
- explicit mention query API
- server push policy для mention updates

---

## MENT-1. Mention appears in home after incoming mentioned message
```
scenario mention appears in home after incoming mentioned message

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob {
body: "hi"
mention: bob
}

session bob
bootstrap home

expect feeds
expect mentions
expect shared snapshot
```

- mention-derived state має з'являтися у home
- mention є частиною view, а не окремим message lifecycle state

---

## MENT-2. Read clears mention when mention boundary is covered
```
scenario read clears mention when mention boundary is covered

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob {
body: "hi"
mention: bob
}

session bob
query inbox peer alice
session bob
send read peer alice for last

session bob
bootstrap home

expect feeds
expect not mentions
expect shared snapshot
```

- mention-derived state має зникати після explicit read,
  якщо unread mention більше не лишилось
- mention не є незалежним від read boundary

---

## MENT-3. Replay alone does not clear mention state
```
scenario replay alone does not clear mention state

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob {
body: "hi"
mention: bob
}

session bob
query events peer alice after cursor

session bob
bootstrap home

expect feeds
expect mentions
expect shared snapshot
```

- replay/history view саме по собі не означає read
- mention не повинен зникати без explicit read action

---

## MENT-4. Hidden message does not produce visible mention state
```
scenario hidden message does not produce visible mention state

given
alice has clearance secret
message m1 has classification topsecret
message m1 field body visible at level topsecret
message m1 field mention visible at level topsecret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

- hidden message не повинен породжувати visible mention-derived state
- mention visibility підпорядковується тій самій policy semantics, що і message visibility
- hidden mention source message не повинен з'являтися ні в mention count,
  ні в latest mention anchor

---

## MENT-5. Mention and unread are related but not identical
```
scenario mention and unread are related but not identical

session alice
connect
auth

add bob to roster

session bob
connect
auth

add alice to roster

session alice
send message to bob "plain"
session alice
send message to bob {
body: "important"
mention: bob
}

session bob
bootstrap home

expect feeds
expect mentions
expect shared snapshot
```

- unread може існувати без mention
- mention є stronger derived signal поверх unread-visible messages
