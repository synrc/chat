SYNRC 💬 CHAT
=============

![image](https://github.com/erpuno/chat/assets/144776/b7e0b60b-4b61-4ff6-a8c9-e27f2e4c4e7c)

💬 CHAT: Instant Messenger respects IETF 3394 3565 5280 5480 5652 5755 8551 ITU
ASN.1 X.509 CMS PKCS-10 PCKS-7 OCSP LDAP DNS X9-42 X9-62 X25519 X488 SECP384r1.

Features
--------

* X.509 OpenSSL, LiberSSL for security;
* SYN/MAIL message delivery system;
* CA for X.509 client certificate enrollment;

CHAT protocol
-------------

The CHAT protocols communicates with `actions/:client`, `events/:client`, `devices/:phone`,
`contacts/:roster`, `private/:roster/:roster` MQTT topics, sending through them
`Index`, `Typing`, `Search`, `Feature`, `Service`, `Desc`, `Presence`,
`Friend`, `Tag`,  `Link`, `Message`, `Member`, `Room`, `Contact`,
`Star`, `RoomStar`, `Ack`, `Auth`, `Roster`, `Profile`, `History`, `push`, `io`
DER-serialized ASN.1 defined messages.

The CHAT protocol is implemented in the set of sub-protocol modules:
FILE, HISTORY, LINK, MESSAGE, PRESENSE, PROFILE, PUSH, ROOM, ROSTER,
SEARCH, AUTH. For full specification follow `priv/design` folder. 
The CHAT server implementation relies only on ISO/IETF connections
such as DNSSEC, X.509 CSR, LDAP, QUIC, WebSocket.

* [CHAT N2O PROTO SPEC](priv/proto/CHAT.asn1) ASN.1/DER over MQTT/QUIC

CHAT is a simple instant messaging server based on ISO standards.
It uses ASN.1 defined protocol and DER binary serialization from Erlang/OTP
across applications: MAIL, LDAP, NS, CA. Secure by default.
The CHAT application has Sign/Verify, Encrypt/Decrypt feature enabled for
every single message passed by. The delivered messages are being deleted
from instance after recipient acknowledgment.
This is Keybase, OTR, PGP (you name it) replacement for secure X.509 ASN.1 defined communications.

CHAT server
-----------

```sh
$ sudo apt install erlang elixir
$ git clone git@github.com:synrc/chat && cd chat
$ mix deps.get
$ mix release
$ _build/dev/rel/chat/bin/chat daemon
$ _build/dev/rel/chat/bin/chat remote
```

```elixir
Erlang/OTP 28 [erts-16.0.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit] [dtrace]

Eshell V16.0.2 (press Ctrl+G to abort, type help(). for help)
iex(1)> :application.which_applications
[
  {:chat, 'CHAT X.509 Instant Messenger mqtt://chat.synrc.com', '6.6.14'},
  {:ssl_verify_fun, 'SSL verification functions for Erlang\n', '1.1.6'},
  {:mnesia, 'MNESIA  CXC 138 12', '4.20.1'},
  {:hex, 'hex', '2.0.0'},
  {:inets, 'INETS  CXC 138 49', '7.5'},
  {:ssl, 'Erlang/OTP SSL application', '10.6.1'},
  {:public_key, 'Public key infrastructure', '1.11.3'},
  {:asn1, 'The Erlang ASN1 compiler version 5.0.17', '5.0.17'},
  {:crypto, 'CRYPTO', '5.0.5'},
  {:mix, 'mix', '1.12.2'},
  {:iex, 'iex', '1.12.2'},
  {:elixir, 'elixir', '1.12.2'},
  {:compiler, 'ERTS  CXC 138 10', '8.0.4'},
  {:stdlib, 'ERTS  CXC 138 10', '3.17'},
  {:kernel, 'ERTS  CXC 138 10', '8.2'}
]
```

Development Reports
-------------------

* [DR-1] <a href="https://tonpa.guru/stream/2010/2010-10-18 LDAP.htm">2010-10-18 LDAP</a><br>
* [DR-2] <a href="https://tonpa.guru/stream/2020/2020-02-03 Кваліфікований Електронний Підпис.htm">2020-02-03 Кваліфікований Підпис</a><br>
* [DR-3] <a href="https://tonpa.guru/stream/2023/2023-06-22 Месенжер.htm">2023-06-22 CMS Месенжер (Пітч)</a><br>
* [DR-4] <a href="https://chat.erp.uno">2023-06-30 ЧАТ X.509 (Домашня сторінка)</a><br>
* [DR-5] <a href="https://tonpa.guru/stream/2023/2023-07-05 CMS SMIME.htm">2023-07-05 CMS S/MIME</a><br>
* [DR-6] <a href="https://tonpa.guru/stream/2023/2023-07-16 CMS Compliance.htm">2023-07-16 CMS Compliance</a><br>
* [DR-7] <a href="https://tonpa.guru/stream/2023/2023-07-20 LDAP Compliance.htm">2023-07-20 LDAP Compliance</a><br>
* [DR-8] <a href="https://ldap.erp.uno">2023-07-25 LDAP 13.7.24 (Домашня сторінка)</a><br>
* [DR-9] <a href="https://ca.erp.uno">2023-07-30 CA X.509 (Домашня сторінка)</a><br>
* [DR-10] <a href="https://tonpa.guru/stream/2023/2023-07-21 CMP CMC EST.htm">2023-07-21 CMP/CMC/EST</a><br>
* [DR-11] <a href="https://tonpa.guru/stream/2023/2023-07-27 MLS.htm">2023-07-21 MLS ROOM CHAT</a><br>
* [DR-12] <a href="https://tonpa.guru/stream/2023/2023-08-05 CA CURVE.htm">2023-08-05 CA CURVE</a><br>
* [DR-13] <a href="https://tonpa.guru/stream/2023/2023-08-07 CHAT ASN.1.htm">2023-08-07 CHAT ASN.1</a><br>
* [DR-14] <a href="https://tonpa.guru/stream/2023/2023-08-08 ASN.1 Компілятор.htm">2023-08-08 ASN.1 Компілятор</a><br>
* [DR-15] <a href="https://tonpa.guru/stream/2023/2023-08-10 CHAT Техзавдання.htm">2023-08-10 CHAT Техзавдання</a><br>
* [DR-16] <a href="https://tonpa.guru/stream/2023/2023-08-11 ITU X Series.htm">2023-08-11 ITU X Series</a><br>
* [DR-17] <a href="https://tonpa.guru/stream/2023/2023-08-13 SWIFT X.509.htm">2023-08-13 SWIFT X.509</a><br>
* [DR-18] <a href="https://tonpa.guru/stream/2023/2023-08-15 CHAT Техноробочий проєкт.htm">2023-08-15 CHAT Техноробочий проєкт</a><br>
* [DR-19] <a href="https://tonpa.guru/stream/2023/2023-09-01 ASN1.EX X.680.htm">2023-09-01 ASN1.EX X.680 Тензори</a><br>
* [DR-20] <a href="https://tonpa.guru/stream/2023/2023-09-07 Криптоніт.htm">2023-09-07 Криптоніт</a><br>

Credits
-------

* Namdak Tonpa

OM A HUM
