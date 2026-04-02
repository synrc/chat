> See DSL-CORE.md for language definition
## PAGE-1. Pagination

```
scenario inbox pagination

given
  private feed alice<->bob has messages
    1 from alice "p1"
    2 from bob "p2"
    3 from alice "p3"
    4 from bob "p4"
    5 from alice "p5"
    6 from bob "p6"
    7 from alice "p7"
    8 from bob "p8"
    9 from alice "p9"
    10 from bob "p10"
    11 from alice "p11"

session bob
connect
auth

query inbox alice limit 10

expect result items <= 10
expect more

query inbox continue

expect result items
```

## PAGE-2. Continue without initial query
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

## PAGE-3. Continue after feed change
```
scenario continue after feed change

session bob
connect
auth

query inbox alice limit 10
expect result items

query inbox carol continue

expect error badRequest
```
- continue прив'язаний до конкретного feed
- зміна feed інвалідовує continuation context

## PAGE-4. Empty page no more
```
scenario empty page no more

given
  private feed carol<->dave has messages
    1 from carol "x1"
    2 from dave "x2"
    3 from carol "x3"

session bob
connect
auth

query inbox alice limit 10

expect result items = 0
expect not more
```
- пустий результат з hasMore=false означає кінець даних
---

## PAGE-5. Home bootstrap pagination

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
## PAGE-6. Home continue without initial query
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
## PAGE-7. Home pagination no duplicate feeds
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
## PAGE-8. Empty home page no more
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
## PAGE-9. Event streaming

```
scenario event streaming

session bob
connect
auth

query events alice after 100 limit 10

expect events count <= 10
expect next
expect more
```
## PAGE-10. Event replay pagination
```
scenario event replay pagination

session bob
connect
auth

query events alice after 100 limit 2

expect events count <= 2
expect next

query events alice after next

expect events
```
## PAGE-11. Replay no more
```
scenario replay no more

session bob
connect
auth

query events alice after cursor

expect empty replay
expect not more
```
- коли немає нових подій, replay повертає пустий результат
---

