FAV: Favorites Protocol
=======================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/1/api/phone/:phone` — MQTT
* `events/1//api/anon/:client/:token` — MQTT

Records
-------

```
-record('Star',     {roster_id=[]::[] | binary(),
                     message=[] :: #'Message'{},
                     tags=[] :: [] | list(integer()),
                     status=[] :: [] | add | remove}).

-record('Tag',      {id=[]::[]|integer(),
                     roster_id=[] :: [] | binary(),
                     name=[] :: binary(),
                     color=[] :: binary(),
                     status=[] :: [] | create | remove | edit}).
```

Overview
--------

Favorites API dedicated for managing favorites feed.

Protocol
--------

### `Tag/create` — Create Tag

```
1. client sends `{'Tag',_,Roster,Name,Color,create}`
             to `events/1//api/anon/:client/:token` once.
```

### `Tag/remove` — Create Tag

```
1. client sends `{'Tag',Id,_,_,_,remove}`
             to `events/1//api/anon/:client/:token` once.
```

### `Tag/edit` — Edit Tag

```
1. client sends `{'Tag',_,Roster,Name,Color,edit}`
             to `events/1//api/anon/:client/:token` once.
```

### `Star/add` — Add to Favorites

```
1. client sends `{'Star',Roster,Msg,Tags,add}`
             to `events/1//api/anon/:client/:token` once.
```

### `Star/remove` — Remove from Favorites

```
1. client sends `{'Star',Roster,Msg,Tags,remove}`
             to `events/1//api/anon/:client/:token` once.
```
