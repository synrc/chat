> See DSL-CORE.md for language definition

# DSL-VISIBILITY

Сценарії для visibility, hidden state і field-level filtering поверх protocol truth

Цей файл описує visibility semantics поверх protocol truth:

- visible / hidden
- field-level visibility
- relation між access decision і view filtering
- relation між hidden і deleted
- consistency між inbox-derived visibility і policy layer

---

## VIS-1. Message is hidden when clearance is insufficient
```
scenario message is hidden when clearance is insufficient

given
message m1 has classification topsecret
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 hidden
```

- hidden не означає absent у protocol truth
- visibility визначається policy layer

---

## VIS-2. Message is visible when clearance matches
```
scenario message is visible when clearance matches

given
message m1 has classification confidential
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 visible
```

- достатній clearance робить message visible
- visibility лишається view-layer semantics

---

## VIS-3. Field visibility may be stricter than message visibility
```
scenario field visibility may be stricter than message visibility

given
message m1 has classification confidential
message m1 field body visible at level confidential
message m1 field attachment visible at level topsecret
alice has clearance secret

when alice queries inbox

expect access allowed
expect message m1 visible
expect message m1 field body visible
expect message m1 field attachment hidden
```

- message visibility і field visibility є різними рівнями policy
- частина payload може бути hidden без приховування всього message

---

## VIS-4. Access denied does not imply hidden for already classifiable view
```
scenario access denied does not imply hidden for already classifiable view

given
message m1 has classification confidential
alice has clearance secret
alice is banned

when alice queries inbox

expect access denied
expect message m1 visible
```

- access decision і visibility result є різними policy outputs
- deny не обов'язково означає retroactive hide

---

## VIS-5. Hidden and deleted are different states
```
scenario hidden and deleted are different states

given
message m1 has classification topsecret
alice has clearance secret

session alice
connect
auth

session bob
connect
auth

session bob
send message to alice "x"
session bob
delete message "x"

session alice
expect message deleted

when alice queries inbox

expect access allowed
expect message m1 hidden
```

- hidden і deleted не повинні змішуватись
- deleted є message lifecycle state
- hidden є visibility/policy state
