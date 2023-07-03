#!/bin/sh

openssl cms -encrypt -aes256 -secretkeyid 01 -secretkey 0ce6054f58d08d0f5f2af9677f4e14fc -in message.txt -out encrypted.txt -recip client.pem -from server@ -to client@
