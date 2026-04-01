> See DSL-CORE.md for language definition
## Scenario 8. Pagination

```
scenario inbox pagination

session bob
connect
auth

query inbox bob limit 10

expect result items <= 10
expect more

query inbox continue

expect result items
```

## Scenario 8a. Continue without initial query
```
scenario continue without initial query

session bob
connect
auth

query inbox continue

expect error badRequest
```
- continue без попереднього query не має контексту
- сервер не повинен вгадувати feed або cursor

## Scenario 8b. Continue after feed change
```
scenario continue after feed change

session bob
connect
auth

query inbox bob limit 10
expect result items

query inbox alice continue

expect error badRequest
```
- continue прив'язаний до конкретного feed
- зміна feed інвалідовує continuation context

## Scenario 8c. Empty page no more
```
scenario empty page no more

session bob
connect
auth

query inbox bob limit 10

expect result items = 0
expect not more
```
- пустий результат з hasMore=false означає кінець даних
---

## Scenario 8d. Home bootstrap pagination

```
scenario home bootstrap pagination

session bob
connect
auth

bootstrap home limit 10 preview 1

expect roster
expect feeds count <= 10
expect previews
expect shared snapshot
expect more

query home continue

expect feeds
```

- home query підтримує pagination для великого списку feed
- continuation прив'язаний до поточного home query context
- preview є view-даними для home screen, а не full inbox recovery
---
## Scenario 8e. Home continue without initial query
```
scenario home continue without initial query

session bob
connect
auth

query home continue

expect error badRequest
```

- `query home continue` без попереднього `query home` не має continuation context
- сервер не повинен вгадувати bootstrap state
---
## Scenario 8f. Home pagination no duplicate feeds
```
scenario home pagination no duplicate feeds

session bob
connect
auth

bootstrap home limit 10 preview 1

expect feeds
expect shared snapshot
expect more

query home continue

expect feeds
expect not duplicate feeds
```

- paged home result не повинен повторно повертати той самий feed у межах одного bootstrap query
- snapshot anchor має лишатися спільним для всіх сторінок одного home query
---
## Scenario 8g. Empty home page no more
```
scenario empty home page no more

session bob
connect
auth

bootstrap home limit 10 preview 1

expect feeds count = 0
expect not more
```
- пустий home result з `hasMore=false` означає, що bootstrap data відсутні
- snapshot anchor при цьому все одно може бути присутнім
---
## Scenario 9. Event streaming

```
scenario event streaming

session bob
connect
auth

query events bob after 100 limit 10

expect events count <= 10
expect next
expect more
```
## Scenario 9a. Event replay pagination
```
scenario event replay pagination

session bob
connect
auth

query events bob after 100 limit 2

expect events count <= 2
expect next

query events bob after next

expect events
```
## Scenario 9b. Replay no more
```
scenario replay no more

session bob
connect
auth

query events bob after cursor

expect empty replay
expect not more
```
- коли немає нових подій, replay повертає пустий результат
---

