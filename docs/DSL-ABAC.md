> See DSL-CORE.md for language definition

# DSL: ABAC / Access Policy

Цей файл описує сценарії перевірки policy layer (ABAC),
який працює поверх protocol model.

ABAC:

- не змінює Message/Event/Query semantics
- визначає доступ до дій і view

Сценарії тут перевіряють:

- command authorization
- query authorization
- view filtering
---
## ABAC-1. Send allowed by clearance

```
scenario send allowed by clearance

given alice has clearance secret
given message has classification confidential

when alice sends message

expect access allowed
```

- actor може виконати command, якщо subject attributes задовольняють policy
- ABAC перевіряє доступ, а не змінює protocol semantics

---

## ABAC-2. Send denied by clearance
```
scenario send denied by clearance

given alice has clearance confidential
given message has classification secret

when alice sends message

expect access denied
```

- deny означає заборону command
- deny не створює окремого protocol state
---

## ABAC-3. Query events denied by branch policy
```
scenario query events denied by branch policy

given alice has branch civil
given feed room1 has branch military

when alice queries events for group room1

expect access denied
```
- query authorization є окремим policy-рівнем
- actor може бути валідно authenticated, але не мати права на конкретний query
---
## ABAC-4. Query filters restricted messages
```
scenario query filters restricted messages

given alice has clearance confidential
given message m1 has classification confidential
given message m2 has classification secret

when alice queries inbox

expect message m1 visible
expect message m2 hidden
```
- дозволений query не обов'язково означає повну видимість result set
- ABAC може фільтрувати view без зміни canonical message state
---
## ABAC-5. Payload field filtered by policy
```
scenario payload field filtered by policy

given alice has clearance confidential
given message m1 has classification secret
given message m1 field body visible at level confidential
given message m1 field attachment visible at level secret

when alice queries inbox

expect message m1 field body visible
expect message m1 field attachment hidden
```

- ABAC може працювати на field-level visibility
- payload filtering не змінює Message state, а лише view

---

## ABAC-6. Send denied without clearance
```
scenario send denied without clearance

given message has classification confidential

when alice sends message

expect access denied
```

- за відсутності достатніх subject attributes policy повинна deny за замовчуванням
- відсутність clearance не повинна трактуватись як implicit allow

---

## ABAC-7. Send allowed on exact clearance boundary
```
scenario send allowed on exact clearance boundary

given alice has clearance secret
given message has classification secret

when alice sends message

expect access allowed
```

- equality boundary є валідним allow
- policy compare тут є `subject.clearance >= message.classification`

---

## ABAC-8. Query hides all restricted messages
```
scenario query hides all restricted messages

given alice has clearance confidential
given message m1 has classification secret
given message m2 has classification secret

when alice queries inbox

expect message m1 hidden
expect message m2 hidden
```

- якщо actor не має достатнього clearance, весь restricted result set може бути hidden
- allowed query не означає, що хоч один message обов'язково буде visible

---

## ABAC-9. Field visibility is independent inside one message
```
scenario field visibility differs inside one message

given alice has clearance confidential
given message m1 field body visible at level confidential
given message m1 field attachment visible at level secret
given message m1 field metadata visible at level confidential

when alice queries inbox

expect message m1 field body visible
expect message m1 field metadata visible
expect message m1 field attachment hidden
```

- field-level policy може давати різну видимість для різних полів одного message
- field visibility є незалежною від того, що інші fields того ж message можуть бути hidden