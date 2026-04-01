> See DSL-CORE.md for language definition
# DSL-MODERATION

## MOD-1. Ban user
```
scenario ban user

session alice
connect
auth

ban bob

expect bob is banned
```
---
## MOD-2. Banned user cannot send direct message
```
scenario banned user cannot send direct message

session alice
connect
auth

session bob
connect
auth

session alice
ban bob

session bob
send message to alice "hi"

expect error forbidden
```
---
## MOD-3. Unban restores direct messaging
```
scenario unban restores direct messaging

session alice
connect
auth

session bob
connect
auth

session alice
ban bob
unban bob

session bob
send message to alice "hi"

session alice
expect message from bob body "hi"
```
---
## MOD-4. Query moderation list
```
scenario query moderation list

session alice
connect
auth

ban bob
ban carol

query moderation

expect moderation
expect bob in moderation
expect carol in moderation
```
---
## MOD-5. Moderation does not imply roster removal
```
scenario moderation does not imply roster removal

session alice
connect
auth

add bob to roster
ban bob

query roster

expect bob in roster
expect bob is banned
```
---
## MOD-6. Moderation does not imply subscription removal
```
scenario moderation does not imply subscription removal

session alice
connect
auth

add bob to roster
ban bob

query subscriptions

expect subscriptions
expect bob in subscriptions
```
---