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

