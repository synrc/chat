FTP: File Transfer Protocol
===========================

Version 1.0 Maxim Sokhatsky

Endpoints
--------

* `ns.synrc.com:8000/ws` — WS

Tuples
------

* `{ftp,Id,Sid,Filename,Meta,Size,Offset,Block,Data,Status}`
* `{ftpack,Id,Sid,Filename,Meta,Size,Offset,Block,ZeroBin,Status}`

Overview
--------

FTP API covert very simple and fast binary file transfer over websockets.

Protocol
--------

```
1. client sends `{ftp,_,_,_,_,_,_,_,_,_}`
             to `:8000/ws` once.
```

```
2. server sends `{ftpack,_,_,_,_,_,_,_,_,_}`
             to `:8000/ws` once.
```
