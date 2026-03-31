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

