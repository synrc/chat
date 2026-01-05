LOC: Location Protocol
===========================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `actions/:client` — MQTT
* `events/:client` — MQTT

Tuples
------

* `{'Loc',X,Y,Z}`

Overview
--------

Location API dedicated for sending GPS coordinates of the device.

Protocol
--------

### `Loc/` — Send Location

```
1. client sends `{'Loc',X,Y,Z}`
             to `events/1//api/anon/:client/:token` once.
```
