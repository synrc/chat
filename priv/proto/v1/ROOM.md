ROOM: MUC Conversations
========================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `room/Room` — MQTT
* `actions/1/api/:client` — MQTT
* `events/1//api/anon//` — MQTT
* `devices/:phone` — MQTT

Tuples
------

```erlang
-record('Feature',  {id    =[] :: [] | binary(),
                     key   =[] :: [] | binary(),
                     value =[] :: [] | binary(),
                     group =[] :: [] | binary() }).

-record('Member',   {id        =[] :: [] | integer(),
                     container = chain :: atom() | chain | cur,
                     feed_id   =[] :: #muc{} | #p2p{},
                     prev      =[] :: [] | integer(),
                     next      =[] :: [] | integer(),
                     feeds     =[] :: list(),
                     phone_id  =[] :: [] | binary(),
                     avatar    =[] :: [] | binary(),
                     names     =[] :: [] | binary(),
                     surnames  =[] :: [] | binary(),
                     alias     =[] :: [] | binary(),
                     email     =[] :: [] | binary(),
                     vox_id    =[] :: [] | binary(),
                     reader    = 0 :: [] | integer(),
                     update    = 0 :: [] | integer(),
                     settings  =[] :: [] | list(#'Feature'{}),
                     presence  =[] :: [] | online | offline,
                     status    =[] :: [] | admin | member | removed | patch }).

-record('Room',     {id          =[] :: [] | binary(),
                     name        =[] :: [] | binary(),
                     description =[] :: [] | binary(),
                     settings    =[] :: list(),
                     members     =[] :: list(#'Member'{}),
                     admins      =[] :: list(#'Member'{}),
                     data        =[] :: [] | list(#'Desc'{}),
                     type        =[] :: [] | atom() | group | channel,
                     tos         =[] :: [] | binary(),
                     tos_update  = 0 :: [] | integer(),
                     unread      = 0 :: [] | integer(),
                     last_msg    =[] :: [] | #'Message'{},
                     update      = 0 :: [] | integer(),
                     created     = 0 :: [] | integer(),
                     status      =[] :: [] | create | join | leave
                     | ban | unban | add | remove | mute | unmute
                     | patch | get | delete | settings
                     | voice | video }).

```

Overview
--------

TRIBE API serves the MUC groupchat conversations.

Protocol
--------

### `Room/create` — Create MUC

```
1. client sends `{'Room',_,Name,Desc,Settings,Members,Admins,Data,Type,_,_,_,_,_,_,create}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,Name,Desc,Settings,Members,Admins,Data,Type,Tos,TosUpdate,Unread,LastMsg,Update,Created,create}`
             to `actions/1/api/:client/:token` once.
    server sends `{'Message',_,_,_,_,_,_,_,_,_,_,AddMsg,_,_,muc}`
             to `room/:room` members times.
```

### `Room/get` — Get MUC room

```
1. client sends `{'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,get}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,Name,Desc,Settings,Members,Admins,Data,Type,Tos,TosUpdate,Unread,LastMsg,Update,Created,get}`
             to `actions/1/api/:client` once.
```

### `Room/patch` — Modify MUC Settings

```
1. `{'Room',Id,Name,Desc,Settings,_,_,Data,Type,Tos,_,_,_,_,_,patch}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,Name,Desc,Settings,[],[],Type,Tos,_,_,_,_,_,patch}`
             to `room/:room` members times.
```

### `Member/patch` — Modify self Member

```
1. client sends `{'Member',_,_,_,_,_,_,_,Avatar,Names,Surnames,Alias,Email,Vox,_,_,_,_,_,patch}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Member',Id,_,_,_,_,_,_,Avatar,Names,Surnames,Alias,Email,Vox,_,_,_,patch}`
             to `Member/:member` members times.
```

### `Room/add` — Add Members by Admin

```
1. client sends `{'Room',Id,_,_,_,_,Members,Admins,_,_,_,_,_,_,_,add}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,_,_,_,_,Members,Admins,_,_,_,_,_,_,_,add}`
             to `room/:room` members times.
    server sends `{'Message',_,_,_,_,_,_,_,_,_,_,AddMsg,_,_,muc}`
             to `room/:room` members times.
```

### `Room/remove` — Remove Members by Admin

```
1. client sends `{'Room',Id,_,_,_,_,Members,Admins,_,_,_,_,_,_,_,remove}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,remove}`
             to `room/:room` members times.
    server sends `{'Message',_,_,_,_,_,_,_,_,_,_,RemoveMsg,_,_,muc}`
             to `room/:room` members times.

```

### `Room/leave` — Leave Room by self Member

```
1. client sends `{'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,leave}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,_,_,_,_,[Member],_,_,_,_,_,_,_,_,leave}`
             to `room/:room` members times.
    server sends `{'Message',_,_,_,_,_,_,_,_,_,_,LeaveMsg,_,_,muc}`
             to `room/:room` members times.
```


<!-- ### Room/ban — Ban Members by Admin -->

<!-- 1. client sends {'Room',Id,_,_,_,_,Members,_,_,_,_,_,_,_,_,ban}
             to events/1//api/anon// once. -->

<!-- 2. server sends {'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,ban}
              to room/:room` members times. -->

<!-- ### Room/unban — Unban Members by Admin -->

<!-- 1. client sends {'Room',Id,_,_,_,_,Members,_,_,_,_,_,_,_,_,unban}
              to events/1//api/anon// once. -->

<!-- 2. server sends {'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,unban}
              to room/:room` members times. -->


### `Room/mute` — Mute Group

```
1. client sends `{'Room',Id,_,_,_,_,Members,_,_,_,_,_,_,_,_,mute}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,mute}`
             to `ses/:phone` members times.
```

### `Room/unmute` — Unmute Group

```
1. client sends `{'Room',Id,_,_,_,_,Members,_,_,_,_,_,_,_,_,unmute}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Room',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,unmute}`
             to `ses/:phone` members times.
```

