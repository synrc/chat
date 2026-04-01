> See DSL-CORE.md for language definition
# DSL-GROUP

## GROUP-1. Create group
```
scenario create group

session alice
connect
auth

create group room1

expect group room1 exists
expect alice is owner
expect alice is member
```
---
## GROUP-2. Add member to group
```
scenario add member to group

session alice
connect
auth

create group room1

add bob to group room1

expect bob is member of group room1
```
---
## GROUP-3. Member can send message
```
scenario member can send message

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1

session bob
send message to group:room1 "hi"

expect delivered
```
---
## GROUP-4. Non-member cannot send message
```
scenario non-member cannot send message

session alice
connect
auth

session bob
connect
auth

session alice
create group room1

session bob
send message to group:room1 "hi"

expect error forbidden
```
---
## GROUP-5. Member can query inbox
```
scenario member can query group inbox

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1
send message to group:room1 "m1"

session bob
query inbox group:room1

expect result items
```
---
## GROUP-6. Non-member cannot query inbox
```
scenario non-member cannot query group inbox

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
send message to group:room1 "m1"

session bob
query inbox group:room1

expect error forbidden
```
---
## GROUP-7. Remove member loses access
```
scenario removed member loses access

session alice
connect
auth

session bob
connect
auth

session alice
create group room1
add bob to group room1

session bob
query inbox group:room1
expect result items

session alice
remove bob from group room1

session bob
query inbox group:room1

expect error forbidden
```
---
## GROUP-8. Delete group
```
scenario delete group

session alice
connect
auth

create group room1

delete group room1

query inbox group:room1

expect error notFound
```
---