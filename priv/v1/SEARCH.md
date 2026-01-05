SEARCH: Directory Search
========================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/:client` — MQTT
* `events/:client` — MQTT

Tuples
------

```erlang
-record('Search',   {id       =[] :: [] | integer(),
                     ref      =[] :: [] | binary(),
                     field    =[] :: [] | binary(),
                     type     =[] :: [] | '==' | '!=' | 'like',
                     value    =[] :: [] | term(),
                     status   =[] :: [] | profile | roster | contact | member | room }).
```

Overview
--------

User emits Search request and gets Contacts (which represents
the found rosters) packed in Roster message (the search result envelop).

Protocol
--------

### `Search/contacts` — Search Contacts

```
1. client sends `{'Search,RosterId,Ref,Field,'==',Value,Status}`
             to `events/1//api/anon//` once.
```

```

2. server sends `{io, {ok, Ref},{'Roster,Id,_,_,_,UserList,_,_,_,_,_,_,Status}}`
             to `actions/1/api/:client` once.
```

