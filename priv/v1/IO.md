IO: Exceptions and Effects Protocol
===================================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/:client` — MQTT

Tuples
------

```erlang
-record(error, {code=[] :: [] | atom(), src=[] :: [] | binary()}).
```
```erlang
-record(ok,    {code=[] :: [] | atom(), src=[] :: [] | binary()}).
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
