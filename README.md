SYNRC 💬 CHAT
=============

[![Actions Status](https://github.com/synrc/chat/workflows/mix/badge.svg)](https://github.com/synrc/chat/actions)
[![Hex pm](https://img.shields.io/hexpm/v/chat.svg?style=flat)](https://hex.pm/packages/chat)

SYNRC 💬 CHAT Instant Messenger respects IETF 3394 3565 5280 5480 5652 5755 8551 ITU
ASN.1 X.509 CMS PKCS-10 PCKS-7 OCSP LDAP DNS X9-42 X9-62 X25519 X488 SECP384r1

Features
--------

* X.509 CMS Envelope for Key Management;
* MNESIA records delivery system;
* CMP EST for X.509 CA enrollment;

Files
-----

```
├── config
│   └── config.exs
├── include
│   ├── CHAT-v2.hrl
│   ├── meta.hrl
│   ├── push.hrl
│   └── roster.hrl
├── lib
│   ├── application.ex
│   ├── auth.ex
│   ├── chat.ex
│   ├── inbox.ex
│   ├── message.ex
│   ├── p1.ex
│   ├── p3.ex
│   ├── p7.ex
│   └── roster.ex
├── priv
│   ├── v1
│   │   ├── AlgorithmInformation-2009.asn1
│   │   ├── CryptographicMessageSyntax-2009.asn1
│   │   ├── MESSAGE-v1.asn1
│   │   ├── PKIX-CommonTypes-2009.asn1
│   │   ├── PKIX1-PSS-OAEP-Algorithms-2009.asn1
│   │   ├── PKIX1Explicit-2009.asn1
│   │   ├── PKIX1Implicit-2009.asn1
│   │   └── PKIXAlgs-2009.asn1
│   └── v2
│       ├── CHAT-v2.asn1
│       ├── CryptographicMessageSyntax-2009.asn1
│       ├── PKCS-10.asn1
│       ├── PKIX1Explicit-2009.asn1
│       └── PKIX1Implicit-2009.asn1
├── src
│   └── CHAT-v2.erl
├── mix.exs
├── LICENSE
├── index.html
└── README.md
```

CHAT protocol
-------------

* [Zen Crypted Buddha Protocol](https://protocol.zencrypted.uk)

CHAT is a simple instant messaging server based on ISO standards.
It uses ASN.1 defined protocol and DER binary serialization from Erlang/OTP
across applications: MAIL, LDAP, NS, CA. Secure by default.
The CHAT application has Sign/Verify, Encrypt/Decrypt feature enabled for
every single message passed by. The delivered messages are being deleted
from instance after recipient acknowledgment.
This is Keybase, OTR, PGP (you name it) replacement for secure
X.509 ASN.1 defined communications.

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
Erlang/OTP 28 [erts-16.0.2] [source] [64-bit]
  [smp:8:8] [ds:8:8:10] [async-threads:1] [jit] [dtrace]

Eshell V16.0.2 (press Ctrl+G to abort, type help(). for help)
iex(1)> :application.which_applications
[
  {:chat, 'CHAT X.509 Instant Messenger tcp://chat.erp.uno', '9.1.2'},
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

* [2010-10-18 LDAP](https://tonpa.guru/stream/2010/2010-10-18 LDAP.htm)
* [2020-02-03 Кваліфікований Підпис](https://tonpa.guru/stream/2020/2020-02-03 Кваліфікований Електронний Підпис.htm)
* [2023-06-22 CMS Месенжер (Пітч)](https://tonpa.guru/stream/2023/2023-06-22 Месенжер.htm)
* [2023-06-30 ЧАТ X.509 (Домашня сторінка)](https://erp.uno/chat/)
* [2023-07-05 CMS S/MIME](https://tonpa.guru/stream/2023/2023-07-05 CMS SMIME.htm)
* [2023-07-16 CMS Compliance](https://tonpa.guru/stream/2023/2023-07-16 CMS Compliance.htm)
* [2023-07-20 LDAP Compliance](https://tonpa.guru/stream/2023/2023-07-20 LDAP Compliance.htm)
* [2023-07-25 LDAP 13.7.24 (Домашня сторінка)](https://erp.uno/ldap/)
* [2023-07-30 CA X.509 (Домашня сторінка)](https://erp.uno/ca/)
* [2023-07-21 CMP/CMC/EST](https://tonpa.guru/stream/2023/2023-07-21 CMP CMC EST.htm)
* [2023-07-21 MLS ROOM CHAT](https://tonpa.guru/stream/2023/2023-07-27 MLS.htm)
* [2023-08-05 CA CURVE](https://tonpa.guru/stream/2023/2023-08-05 CA CURVE.htm)
* [2023-08-07 CHAT ASN.1](https://tonpa.guru/stream/2023/2023-08-07 CHAT ASN.1.htm)
* [2023-08-08 ASN.1 Компілятор](https://tonpa.guru/stream/2023/2023-08-08 ASN.1 Компілятор.htm)
* [2023-08-10 CHAT Техзавдання](https://tonpa.guru/stream/2023/2023-08-10 CHAT Техзавдання.htm)
* [2023-08-11 ITU X Series](https://tonpa.guru/stream/2023/2023-08-11 ITU X Series.htm)
* [2023-08-13 SWIFT X.509](https://tonpa.guru/stream/2023/2023-08-13 SWIFT X.509.htm)
* [2023-08-15 CHAT Техноробочий проєкт](https://tonpa.guru/stream/2023/2023-08-15 CHAT Техноробочий проєкт.htm)
* [2023-09-01 ASN1.EX X.680 Тензори](https://tonpa.guru/stream/2023/2023-09-01 ASN1.EX X.680.htm)
* [2023-09-07 Криптоніт](https://tonpa.guru/stream/2023/2023-09-07 Криптоніт.htm)

Author
------

* Максим Сохацький


