# MSC-DISCOVERY

## Discover server capabilities

DSL:
```text
scenario discover server capabilities

session alice
connect
auth

query discover server

expect feature protocol.version
expect feature auth.methods
expect feature query.types
```

MSC:
```text
msc DiscoverServerCapabilities;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=server);

  condition HasFeature(protocol.version);
  condition HasFeature(auth.methods);
  condition HasFeature(query.types);
endmsc;
```

Extensions used:
- HasFeature(id)

## Discover auth capabilities

DSL:
```text
scenario discover auth capabilities

session alice
connect

query discover auth

expect feature auth.methods
expect feature auth.refresh
```

MSC:
```text
msc DiscoverAuthCapabilities;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();

  Alice -> Server : DiscoverQuery(scope=auth);

  condition HasFeature(auth.methods);
  condition HasFeature(auth.refresh);
endmsc;
```

Extensions used:
- HasFeature(id)

## Discover feed capabilities

DSL:
```text
scenario discover feed capabilities

session alice
connect
auth

query discover group chat1

expect feature feed.replay
expect feature feed.read_cursor
```

MSC:
```text
msc DiscoverFeedCapabilities;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=feed, target=group:chat1);

  condition HasFeature(feed.replay);
  condition HasFeature(feed.read_cursor);
endmsc;
```

Extensions used:
- HasFeature(id)

## Discover extensions

DSL:
```text
scenario discover extensions

session alice
connect
auth

query discover extension

expect feature extension.inbox
expect feature extension.search
```

MSC:
```text
msc DiscoverExtensions;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=extension);

  condition HasFeature(extension.inbox);
  condition HasFeature(extension.search);
endmsc;
```

Extensions used:
- HasFeature(id)

## Ignore unknown features

DSL:
```text
scenario ignore unknown features

session alice
connect
auth

query discover server

expect feature protocol.version
```

MSC:
```text
msc IgnoreUnknownFeatures;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=server);

  condition HasFeature(protocol.version);
endmsc;
```

Extensions used:
- HasFeature(id)

## Discovery does not move replay cursor

DSL:
```text
scenario discovery does not move replay cursor

session alice
connect
auth

session bob
connect
auth

session bob
query events peer alice after cursor
expect empty replay

query discover server

query events peer alice after cursor
expect empty replay
expect not more
```

MSC:
```text
msc DiscoveryDoesNotMoveReplayCursor;
  instance Alice;
  instance Bob;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Bob -> Server : Connect();
  Bob -> Server : Authenticate(...);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition ReplayEmpty;

  Bob -> Server : DiscoverQuery(scope=server);

  Bob -> Server : EventQuery(peer=alice, after=cursor);
  condition ReplayEmpty;
  condition HasMore = false;
endmsc;
```

Extensions used:
- HasMore
- ReplayEmpty

## Exact discovery form

DSL:
```text
scenario exact discovery form

session alice
connect
auth

query discover scope feed target group:chat1

expect feature feed.replay
```

MSC:
```text
msc ExactDiscoveryForm;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=feed, target=group:chat1);

  condition HasFeature(feed.replay);
endmsc;
```

Extensions used:
- HasFeature(id)

## Unsupported discovery scope

DSL:
```text
scenario unsupported discovery scope

session alice
connect
auth

query discover scope policy

expect error unsupported
```

MSC:
```text
msc UnsupportedDiscoveryScope;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=policy);

  condition Error(unsupported);
endmsc;
```

Extensions used:
- Error(code)

## Unknown discovery target

DSL:
```text
scenario unknown discovery target

session alice
connect
auth

query discover scope feed target group:missing

expect error notFound
```

MSC:
```text
msc UnknownDiscoveryTarget;
  instance Alice;
  instance Server;

  Alice -> Server : Connect();
  Alice -> Server : Authenticate(...);

  Alice -> Server : DiscoverQuery(scope=feed, target=group:missing);

  condition Error(notFound);
endmsc;
```

Extensions used:
- Error(code)
