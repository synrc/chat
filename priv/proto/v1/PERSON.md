PERSON: External Settings
=========================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/:client` — MQTT
* `events/:client` — MQTT

Tuples
------

```erlang
-record('Person',  {id=[] :: [] | binary(),
                    names=[] :: binary(),
                    surnames=[] :: binary(),
                    username=[] :: binary(),
                    phonelist=[] :: list(binary()),
                    alias=[] :: list(),
                    avatar=[] :: binary(),
                    localize=[] :: list(),
                    'NotificationSettings'=[] :: list(),
                    'SoundSettings'=[] :: list(),
                    'ThemeID'=[] :: binary(),
                    'voxImplantID'=[] :: binary(),
                    'voxImplantLogin'=[] :: binary(),
                    'voxImplantPassword'=[] :: binary(),
                    'BlockUsers'=[] :: list(binary()),
                    'balance'= 0 :: integer(),
                    'isParticipants'=[] :: list(atom()),
                    status=[] :: atom() | []}).
```

Overview
--------

PERSON API manages different setting across phone numbers, rosters and roster contacts.
It is also a linking table for external ids, etc.

Protocol
--------

### `Person/get` — Get Person

```
1. client sends `{'Person',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,get}`
             to `events/1//api/anon/:client/:token` once.
```

```
2. server sends `{'Person',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}`
             or `{io,{error,not_authorized},<<>>}`
             to `actions/1/api/:client` once.
```
### `Person/set` — Set Person

```
1. client sends `{'Person',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,set}`
             to `events/1//api/anon/:client/:token` once.
```

```
2. server sends `{'Person',Id,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}`
             or `{io,{error,not_authorized},<<>>}`
             to `actions/1/api/:client` once.
```
