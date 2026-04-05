> See DSL-CORE.md for language definition
## AUTH-1. Basic authenticate

```
scenario basic authenticate

session alice
connect
auth

expect authenticated
expect session created
expect access token
```
- первинна аутентифікація створює session
- після auth клієнт повинен отримати session context
- після auth клієнт повинен отримати access token

## AUTH-2. Resume existing session

```
scenario resume existing session

session alice
connect
auth

disconnect
wait 500ms
reconnect

auth resume

expect authenticated
expect same session
```
- reconnect не повинен сам по собі створювати нову session
- `auth resume` означає спробу відновити існуючу session
- при валідному auth context session повинна бути відновлена

## AUTH-3. Renew access token

```
scenario renew access token

session alice
connect
auth

renew

expect access token refreshed
```
- renew не створює нову session
- renew перевидає access token через refresh token

## AUTH-4. Revoked access token denied

```
scenario revoked access token denied

session alice
connect
auth

revoke access token

disconnect
wait 500ms
reconnect

auth resume

expect error unauthorized
```
- revoke access token інвалідує поточну session
- після revoke відновлення через старий access token не повинно проходити

## AUTH-5. Unsupported auth request

```
scenario unsupported auth

session alice
connect

auth supportedVsn [v3]

expect error unsupported
```
- якщо клієнт пропонує лише непідтримувані параметри (наприклад version), auth не повинен проходити
- сервер повинен явно сигналізувати про unsupported конфігурацію

## AUTH-6. Replay without auth

```
scenario replay without auth

session bob
connect

query events peer alice after cursor

expect error unauthorized
```
- replay не повинен бути доступний без успішної аутентифікації
- connect без auth не дає права на event replay
## AUTH-7. Renew then replay

```
scenario renew then replay

session bob
connect
auth

disconnect
wait 500ms
reconnect

renew

expect access token refreshed

query events peer alice after cursor

expect not error unauthorized
```
- після renew клієнт повинен мати валідний auth context
- після renew replay повинен знову працювати
---
## AUTH-8. Renew does not create new session

```
scenario renew does not create new session

session alice
connect
auth

renew

expect access token refreshed

disconnect
wait 500ms
reconnect

auth resume

expect authenticated
expect same session
```

- renew перевидає credentials у межах тієї самої session
- renew не повинен створювати нову session
---
## AUTH-9. Reconnect alone does not restore auth

```
scenario reconnect alone does not restore auth

session alice
connect
auth

disconnect
wait 500ms
reconnect

query events peer bob after cursor

expect error unauthorized
```

- reconnect сам по собі не відновлює auth context
- для відновлення session потрібен explicit `auth resume` або інший валідний auth flow
---
## AUTH-10. Revoked token does not change protocol state

```
scenario revoked token does not change protocol state

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

session bob
revoke access token

disconnect
wait 500ms
reconnect

auth resume

expect error unauthorized
```

- revoke access token ламає auth context, але не змінює вже існуючий message state
- invalid auth не повинен переписувати protocol history
---
## AUTH-11. Resume preserves access to existing read boundary

```
scenario resume preserves read boundary

session alice
connect
auth

session bob
connect
auth

session alice
send message to bob "m1"

session bob
query events peer alice after cursor
expect events

send read for last

disconnect
wait 500ms
reconnect

auth resume

query events peer alice after cursor

expect empty replay
expect not more
```

- після `auth resume` session повинна бачити той самий read/replay boundary
- reconnect/resume не повинні скидати read cursor semantics

