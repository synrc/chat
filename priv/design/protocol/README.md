CHAT PROTOCOL SPECIFICATION
============================

Version 1.0 Maxim Sokhatsky

Overview
--------

To support the development of messaging apps and IOT infrastructure,
CHAT protocol is designed from the ground up to be the most efficient,
stable and scalable protocol available.  CHAT itself is an open-source
specification for Messaging and IOT applications and is a part of an
open source family of N2O protocols. While it can be used with any
transport we promote MQTT as an efficient binary protocol dedicated
for applications over unreliable networks such as GSM, CDMA and other
wireless networks.

CHAT protocol enables all companies, regardless of size, to build
systems that can compete with the world’s most sophisticated
communication platforms. CHAT protocol has been made open source
for the benefit of the global community of developers. CHAT protocol
powers the SYNRC CHAT SIM (Secure Instand Messenger).

Features
--------

* Media: Voice, Video, File Transfer, GPS, Text
* Multi-User Conferences (Tribes)
* Multi Accounts (Rosters)

Intro
-----

* Messages: Schema Definition
* Endpoints: Topic Subscriptions (MQTT), WebSockets (WS)

Topics
------

* `actions/:vsn/:module/:client_id` — Client Topic

This topic is subscribed when connection established. This is done on server so client don't need to subscribe to this topic. All incoming mesages come to this topic.

* `events/:vsn/:node/:module/:username/:client_id/:token` — Server Topic

The number of these topics are equal to the number of cores. Client sends API requesus to one of these topics and listen for answers on 'actions' topic.

* `ses/:phone` — Devices Broadcast

This topic is dedicated for accumulating all device sessions under the single topic indexed by the phone. If you send to this topic, all devices of the given phone will receive the message. If you have no right to send to this phone nothing will happens. New devices should be subscribed to this topic on registration.

* `ac/:phone_roster` — Friendship Broadcast

This topic is representing the subscription mesh, based on friendship logic. If you send to this topic, all devices of your friends will recieve this message. For sure server will strict you from sending to other topics than yours. New devices of friends should be subscribed to this topic on registration. On friendship all friend devices are added to this topic.

* `p2p/:phone_roster/:phone_roster` — Private Chat

This topic is representing the private chat between two users. The name of the topic is constructed from two sorted roster identifiers, e.g. `380670001234_12525/380670002234_12334`, left phone is always less or equal then right. If you send to this topic, all devices of two counterparties will recieve the message. If you are not owner of one of these rosters, nothing will happen. New devices of counterparties should be subscribed to this topic on registration. On friendship all devices of each counterparty subscribe to this topic.

Message Formats
---------------

* [IO](v1/IO.md) — 1
* [INIT](v1/INIT.md) — 1
* [AUTH](v1/AUTH.md) — 8
* [PERSON](v1/PERSON.md) — 2
* [PROFILE](v1/PROFILE.md) — 9
* [PRESENCE](v1/PRESENCE.md) — 4
* [ROSTER](v1/ROSTER.md) — 9
* [MESSAGE](v1/MESSAGE.md) — 5
* [FRIEND](v1/FRIEND.md) — 7
* [ROOM](v1/ROOM.md) — 6
* [SEARCH](v1/SEARCH.md) — 1
* [FAV](v1/FAV.md) — 5
* [FTP](v1/FTP.md) — 1
* [LOC](v1/LOC.md) — 1

Client API RPC Specification
----------------------------

* `Auth/reg` — Registration
* `Auth/voice` — Voice Call
* `Auth/resend` — Resend
* `Auth/verify` — Verify
* `Auth/login` — Login
* `Auth/logout` — Logout
* `Auth/push` — Write Google or Apple token to Auth table
* `Auth/list` — List of client sessions
* `Tag/create` — Create Tag
* `Tag/remove` — Remove Tag
* `Tag/edit` — Edit Tag
* `Star/add` — Add to Favorites
* `Star/remove` — Remove from Favorites
* `Friend/request` — Friendship Request
* `Friend/confirm` — Confirm friendship
* `Friend/revoke` — Revoke friendship
* `Friend/ban` — Ban friend
* `Friend/unban` — Unban friend
* `Friend/mute` — Mute friend
* `Friend/unmute` — Unute friend
* `Loc/` — Send Location
* `Message/client` — General Sending Message to Subscribers
* `Message/upload` — Sending Async Upload Message
* `Message/edit` — Edit/Remove Message
* `History/get` — Retrieve History
* `Cursor/` — Set cursor
* `Person/get` — Get Person
* `Person/set` — Set Person
* `Profile/get` — Profile retrival
* `Profile/update` — Profile update in friend's rosters
* `Profile/set` — Profile raw set
* `Profile/link` — Link email to Profile
* `Profile/email` — Confirm email
* `Profile/aws` — Get temporary AWS credentials
* `Profile/remove` — Profile remove
* `Profile/migrate` — Profile migration
* `Profile/phone` — Confirm phone migration
* `Room/create` — Create MUC
* `Room/patch` — Modify MUC Settings
* `Room/join` — Join Members by Admin
* `Room/leave` — Leave Members by Admin
* `Room/ban` — Ban Members by Admin
* `Room/unban` — Unban Members by Admin
* `Room/mute` — Mute Group
* `Room/unmute` — Unmute Group
* `Roster/get` — Get Roster
* `Roster/update` — Update Roster
* `Roster/patch` — Update Roster
* `Roster/remove` — Remove Roster
* `Roster/create` — Create Roster
* `Roster/list` — List Rosters
* `Roster/add` — Add Roster Contacts
* `Roster/del` — Delete Roster Contacts
* `Search/contact` — Search Contacts
* `CDR/` — Call Data Record

Payloads
--------

Payloads are MIME-driven, so Video, Audio and Text messages correspond to MIME types.
**Events** come from server and is a subscription topic for client,
**Actions** come from client and is a publishing topic for client.
This is a front channel for raw BERT messages.
Other topics may bind to event or action topics.

Credits
-------

* Maxim Sokhatsky
