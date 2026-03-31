> See DSL-CORE.md for language definition

## Scenario 9c. Delete overrides reordered edit

```
scenario delete overrides reordered edit

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
expect message from alice body "m1"

session alice
delete message "m1"

session alice
edit message "m1" body "m1 edited"

session bob
expect message deleted
expect not message body "m1 edited"
```

- delete має пріоритет над edit/update
- навіть якщо edit приходить після delete, повідомлення не повинно відновлюватись
- reorder подій не повинен ламати final state
- TODO: у майбутньому можна уточнити exact форму через явні Event.id / timestamp
---
## Scenario 9d. Late delete after edit

```
scenario late delete after edit

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
expect message from alice body "m1"

session alice
edit message "m1" body "m1 edited"

session alice
delete message "m1"

session bob
expect message deleted
expect not message body "m1 edited"
```

- delete має пріоритет над попереднім edit
- навіть якщо edit був застосований раніше, delete визначає final state
- final state повідомлення не повинен залежати від проміжного UI state
- TODO: у майбутньому можна уточнити exact форму через явні Event.id / timestamp
---
## Scenario 10. Version

```
scenario version negotiation

session alice
connect

auth supportedVsn [v1, v2]

expect selectedVsn v2
```

---

## Scenario 11. Federation

```
scenario federation routing

session alice
connect brokerA
auth

send message to bob@brokerB "hi"

session bob
connect brokerB
auth

expect message from alice body "hi"
```

---