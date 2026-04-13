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

Author
------

* Максим Сохацький


