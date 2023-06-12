SYNRC CHAT
==========

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

MQTT server
-----------

```erlang
Applications:  [kernel,stdlib,gproc,lager_syslog,pbkdf2,asn1,fs,ranch,mnesia,
                compiler,inets,crypto,syntax_tools,xmerl,gen_logger,esockd,
                cowlib,goldrush,public_key,lager,ssl,cowboy,mochiweb,emqttd,
                erlydtl,kvs,mad,emqttc,nitro,rest,sh,syslog,review]
Erlang/OTP 19 [erts-8.3] [source] [64-bit] [smp:4:4]
              [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Eshell V8.3  (abort with ^G)
starting emqttd on node 'nonode@nohost'
dashboard:http listen on 0.0.0.0:18083 with 4 acceptors.
mqtt:ws listen on 0.0.0.0:8083 with 4 acceptors.
mqtt:tcp listen on 0.0.0.0:1883 with 4 acceptors.
emqttd 2.1.1 is running now
>
```

Open http://127.0.0.1:18083/#/websocket with `admin:public` credentials,
Press Connect, Subscribe, Sned and observe statistics http://127.0.0.1:18083/#/overview.

MQTT client
-----------

```
$ mad com
==> "/Users/maxim/depot/voxoz/emqttc/examples/gen_server"
Compiling /src/gen_server_example.erl
Writing /ebin/gen_server_example.app
OK
bash-3.2$ ./run
Erlang/OTP 19 [erts-8.2] [source] [64-bit] [smp:4:4]
              [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Eshell V8.2  (abort with ^G)
1> [info] [Client <0.58.0>]: connecting to 127.0.0.1:1883
[info] [Client <0.58.0>] connected with 127.0.0.1:1883
[info] [Client <0.58.0>] RECV: CONNACK_ACCEPT
Client <0.58.0> is connected
[warning] [simpleClient@127.0.0.1:64618] resubscribe [{<<"TopicA">>,1}]
Message from TopicA: <<"hello...1">>
Message from TopicB: <<"hello...1">>
```

Credits
-------

* Maxim Sokhatsky

OM A HUM
