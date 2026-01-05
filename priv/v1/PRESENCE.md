PRESENCE: Roster Notifications
==============================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/:client` — MQTT
* `contacts/:roster` — MQTT
* `muc/:room` — MQTT

Tuples
------

```erlang
-record('Contact',  {phone_id  =[] :: [] | binary(),
                     avatar    =[] :: [] | binary(),
                     names     =[] :: [] | binary(),
                     surnames  =[] :: [] | binary(),
                     nick      =[] :: [] | binary(),
                     email     =[] :: [] | binary(),
                     vox_id    =[] :: [] | binary(),
                     reader    = 0 :: [] | integer(),
                     unread    = 0 :: [] | integer(),
                     last_msg  =[] :: [] | #'Message'{},
                     update    = 0 :: [] | integer(),
                     settings  =[] :: [] | list(#'Feature'{}),
                     presence  =[] :: [] | atom(),
                     status    =[] :: [] | request | authorization | internal
                                         | friend | last_msg | ban | banned | deleted }).
```

Overview
--------

PRESENCE protocol is a set of notification messages informing Contacts changing in Rosters.

Protocol
--------

```
1. server issues `{'Contact',PhoneId,Avatar,_,_,_,_,_,_,_,_,_,_,_,_}`
              to `ac/:phone_id` and `muc/:phone_id` on avatar changing.
```

```
2. server issues `{'Contact',PhoneId,_,Names,Surnames,_,_,_,_,_,_,_,_,_,_}`
              to `ac/:phone_id` on name changing.
```

```
3. server issues `{'Contact',PhoneId,_,_,_,_,_,_,_,_,_,_,_,Presence,_}`
              to `ac/:phone_id` and `muc/:phone_id` on presence changing.
```

```
4. server issues `{'Contact',PhoneId,_,_,_,_,_,_,_,_,_,_,_,_,Status}`
              to `ac/:phone_id` on status changing.
```
