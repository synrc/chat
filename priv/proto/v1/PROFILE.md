PROFILE: Managing Phone Accounts
================================

Version 1.0 Maxim Sokhatsky

Endpoints
---------

* `actions/1/api/:client` — MQTT
* `events/1//api/anon//`  — MQTT
* `devices/:phone`        — MQTT



Records
-------

Profile represents Device or Phone for your Accounts visible to network as integer identifiers.
Profile has one-to-one linkage to Person and may hold custom data.

```erlang
-record('Profile',  {phone     =[] :: [] | binary(),
                     services  =[] :: list(#'Service'{}),
                     rosters   =[] :: list(#'Roster'{} | integer()),
                     settings  =[] :: list(#'Feature'{}),
                     update    = 0 :: integer(),
                     balance   = 0 :: integer(),
                     presence  =[] :: [] | atom(),
                     status    =[] :: [] | atom()}).

```

```erlang

-record('Service',  {id         =[] :: [] | binary(),
                     type       =[] :: [] | email | vox | aws,
                     data       =[] :: term(),
                     login      =[] :: [] | binary(),
                     password   =[] :: [] | binary(),
                     expiration =[] :: [] | integer(),
                     status     =[] :: [] | verified | added}).
```

Overview
--------

ROSTER API manages different accounts with different contact lists.

Protocol
--------

### `Profile/get` — Profile retrival

```
1. client sends `{'Profile',Phone,_,_,_,_,_,get}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Profile',Phone,_,_,_,_,_,get}`
             or `{io,{error,not_authorized},<<>>}`
             to `actions/1/api/:client` once.
```

### `Profile/update` — Profile update in friend's rosters

```
1. client sends `{'Profile',Phone,_,_,_,Time,_,update}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Profile',Phone,_,_,_,Time,_,update}`
             or `{io,{error,not_authorized},<<>>}`
             to `actions/1/api/:client` once.
```

### `Profile/set` — Profile raw set

```
1. client sends `{'Profile',Phone,_,_,_,_,_,set}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Profile',Phone,_,_,_,Time,_,set}`
             or `{io,{error,not_authorized},<<>>}`
             to `actions/1/api/:client` once.
```

### `Profile/link` — Link email to Profile

```
1. client sends `{'Profile',Phone,Services,_,_,_,_,_,link}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{io, Result, <<>>}`
             to `actions/1/api/:client` once.
```

Result:

* `{ok,email_sent}` — send email to email from Services.

### `Profile/email` — Confirm email

```
1. client sends `{'Profile',Phone,Services,_,_,Time,_,email}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{io, Result, <<>>}`
             to `actions/1/api/:client` once.
```

Result:

* `{ok,verified}` — email linked successfully.
* `{error,wrong_code}` — the verification has failed.

### `Profile/aws` — Get temporary AWS credentials

```
1. client sends `{'Profile',Phone,_,_,_,_,_,aws}`
             to `events/1//api/anon//` once.
```

```
2. server sends 
       `{io,{ok,aws},{'Service',_,aws,_,_,_,_,added}}`  — temporary credentials were requested.
    or `{io,{ok,aws},{'Service',AccessKeyId,aws,_,SecretAccessKey,SessionToken,Expiration,verified}}` — temporary credentials were created successfully.
    or `{io,{error,aws},<<>>}` — the creation has failed.
    to `actions/1/api/:client` once.
```

### `Profile/remove` — Profile remove

```
1. client sends `{'Profile',Phone,_,_,_,_,_,remove}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{'Profile',Phone,_,_,_,_,_,_,remove}`
             or `{io,{error,not_found},<<>>}`
             to `actions/1/api/:client` active session of times.
```

```
3. server sends `{'Contact',PhoneId,_,_,_,_,_,_,_,_,_,_,_,_,deleted}
             to `ses/:counterparty` once.
```


### `Profile/migrate` — Profile migration

```
1. client sends `{'Profile',NewPhone,_,_,_,_,Time,_,migrate}`
             to `events/1//api/anon//` once.
```

```
2. server sends `{io, Result, <<>>}`
             to `actions/1/api/:client` once.
```

Result:

* `{ok,migration}` — proceed the migration to a new phone.

### `Profile/phone` — Confirm Phone Migration

```
1. client sends `{'Profile',NewPhone,_,_,_,Time,_,phone}`
             or `{io,{error,not_authorized},<<>>}`
             to `actions/1/api/:client` once.
```
