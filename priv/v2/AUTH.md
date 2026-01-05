AUTH: Client Authentication
===========================

Version 2.0 Maxim Sokhatsky

Endpoints
--------

* `actions/:client` — MQTT
* `events/:client` — MQTT

Binary
------

The binary of `Auth` message holds 286-bit word (36 bytes).

```
+----------+----+-------------------------------------+
| field    | sz | description                         |
+----------+----+-------------------------------------+
| record   | 04 | API function (0000)                 |
| vsn      | 04 | API version (0—15)                  |
| type     | 04 | Type of the Auth request (0—15)     |
| services | 04 | Reqested or allowed services (0—15) |
| os       | 03 | The OS code (0—7)                   |
| online   | 01 | online presence (0—1)               |
| attempts | 02 | Number of login attempts (0—3)      |
| token    | 48 | Auth token (0—281474976710655)      |
| device   | 48 | Device id (0—281474976710655)       |
| push     | 48 | Push token (0—281474976710655)      |
| client   | 48 | Client id (0—281474976710655)       |
| sms      | 14 | SMS verification code (0—16383)     |
| phone    | 50 | Phone number (0—1125899906842623)   |
| broker   | 08 | MQTT client id (0—255)              |
+----------+----+-------------------------------------+
```

Sample of `Auth` table in memory:

```
+-------+------------+--------+----------+---------+----------+
| TOKEN | PHONE      | DEVICE | CLIENT   | OS      | SERVICES |
+-------+------------+--------+----------+---------+----------+
| 12131 | 3800001122 | APPLE1 | emqttd_1 | iOS     | [ua]     |
| 10293 | 3800000000 | NEXUS1 | emqttd_2 | Android | [auth]   |
| 10294 | 3800000001 | NEXUS2 | emqttd_3 | Android | [auth]   |
| 12323 | 3800000000 | SONY02 | emqttd_4 | Android | [auth]   |
+-------+------------+--------+----------+---------+----------+
```

Auth Types
----------

```
+------+--------------+
| bin  | desc         |
+------+--------------+
| 0000 | N/A          |
| 0001 | registration |
| 0010 | resent       |
| 0011 | verify       |
| 0100 | login        |
| 0101 | logout       |
| 0110 | push         |
| 0111 | list         |
| 1xxx | N/A          |
+------+--------------+
```
