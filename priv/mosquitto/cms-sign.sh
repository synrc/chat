#!/bin/sh

openssl cms -sign -in message.txt -text -out signature.txt -signer client.bun
