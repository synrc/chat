SYNRC 💬 CHAT
=============

![image](https://github.com/erpuno/chat/assets/144776/b7e0b60b-4b61-4ff6-a8c9-e27f2e4c4e7c)

Features
--------

* X.509 OpenSSL, LiberSSL for security;
* MQTT for CHAT application;
* NS for DNSSEC domain security;
* LDAP for user directory;
* SYN/MAIL message delivery system;
* CA for X.509 client certificate enrollment;
* N2O based CHAT protocol.

CHAT protocol
-------------

The CHAT protocols communicates with `actions/:vsn/:module/:client_id`, `events/:vsn/:node/:module/:username/:client_id/:token`,
`devices/:phone`, `contacts/:phone_roster`, `private/:phone_roster/:phone_roster` MQTT topics, sending through them
`Index`, `Typing`, `Search`, `Feature`, `Service`, `Desc`, `Whitelist`, `Presence`,  `Friend`, `Tag`,  `Link`, `StickerPack`,
`Message`, `Member`, `Room`, `Contact`, `Star`, `RoomStar`, `Ack`, `Auth`, `Roster`, `Profile`, `History`, `push`, `io` ETF-serialized messages.

The CHAT protocol is implemented in the set of sub-protocol modules:
FILE, HISTORY, LINK, MESSAGE, PRESENSE, PROFILE, PUSH, ROOM, ROSTER, SEARCH, AUTH. For full specification follow `priv/design` folder.
The CHAT server implementation relies only on ISO/IETF connections such as DNSSEC, X.509 SCR, LDAP, QUIC, WebSocket, MQTT.

* [CHAT N2O PROTO SPEC](priv/proto) Erlang Term Format ETF/BERT over MQTT/QUIC

QUIC library
------------

```
$ git clone git@github.com:microsoft/msquic
$ sudo apt install liblttng-ust-dev lttng-tools
$ mkdir build && cd build
$ cmake ..
$ cmake --build .

```

NanoMQ MQTT/QUIC server
-----------------------

```erlang
$ git clone git@github.com:emqx/nanomq
$ cd nanomq 
$ git submodule update --init --recursive
$ mkdir build && cd build
$ cmake -G Ninja -DNNG_ENABLE_QUIC=ON ..
$ sudo ninja install
>
```

MQTT client
-----------

```
 1> {ok, Conn} = emqtt:start_link([
       {client_id, <<"5HT">>},
       {ssl, true},
       {port, 8883},
       {ssl_opts, [
           {verify,verify_peer},
           {certfile,"cert/ecc/Max Socha.pem"},
           {keyfile,"cert/ecc/Max Socha.key"},
           {cacertfile,"cert/ecc/caroot.pem"}]}]).
 {ok,<0.193.0>}
 2> emqtt:connect(Conn).
 {ok,undefined}
 3> emqtt:subscribe(Conn, {<<"hello">>, 0}).
 {ok,undefined,[0]}
 4> emqtt:publish(Conn, <<"hello">>, <<"Hello World!">>, 0).
 ok
 5> flush().
 Shell got {publish,#{client_pid => <0.193.0>,dup => false,
                     packet_id => undefined,payload => <<"Hello World!">>,
                     properties => undefined,qos => 0,retain => false,
                     topic => <<"hello">>}}
 ok
```

Credits
-------

* Maxim Sokhatsky

OM A HUM
