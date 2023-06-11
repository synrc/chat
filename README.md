SYNRC CHAT
==========

Features
--------

* Open-Source 5HT protocol
* X.509 OpenSSL, LiberSSL security
* MQTT server for CHAT application
* LDAP server for ERP/1 integration
* SYN/MAIL message delivery system
* CA Server for X.509 certificate enrollment
* CHAT Application

SYNRC CHAT protocol
-------------------

* [BERT/MQTT SPEC](priv/design/protocol/)

SYNRC MQTT Server
-----------------

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

SYNRC MQTT Client
-----------------

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
