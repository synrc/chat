INIT: Device Initialization
===========================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/1/:node/api/:client` — MQTT
* `events/1/:node/api/anon/:client/:token`

Tuples
------

* `{vnode_max, Node}`
* `{init, Token}`
* `{'Token',Token}`
* `{io, Actions, Token}`

Overview
--------

INIT API is dedicated for initial device token issuing or initialization.
You may think of it as cookie string that can be used to identify
storage of backend variables per EMQ session. EMQ session can be stored
inside this token.

Protocol
--------

```
1. client connects
       to `ns.synrc.com:8083` port.
```

```
2. client subscribes
       to `actions/1/api/:client` automatically.
```

```
3. server send `{vnode_max, Node}`
            to `actions/1/api/:client` automatically.
```

```
4. client sends `{init, Token}`
             to `events/1/2/api/anon/:client`.
```

```
5. server sends `{io,Actions,{'Token',Token}}`
             to `actions/1/api/:client` once.
```
