IO: Exceptions and Effects Protocol
===================================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/1/:node/api/:client` — MQTT

Tuples
------

```erlang
-record(error, { code=[] :: [] | binary() }).
```

```erlang
-record(ok, { code=[] :: [] | binary() | {atom(), binary()}}).
```
```erlang
-record(error2, {code=[] :: [] | atom(), src=[] :: [] | binary()}).
```
```erlang
-record(ok2,    {code=[] :: [] | atom(), src=[] :: [] | binary()}).
```
```erlang
-record(io, { code=[] :: [] | #ok{} | #error{} | #ok2{} | #error2{},
              data=[] :: [] | <<>> | { atom(), binary() | integer() } }).
```

Overview
--------

IO PROTOCOL is intended to transport return codes, JavaScript actions, Exceptions and other server effects.

Protocol
--------

```
1. server issues `{io,_,_}`
              to `actions/1/api/:client` randomly.
```
