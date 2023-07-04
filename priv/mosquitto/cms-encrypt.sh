#!/bin/sh

openssl cms -encrypt -aes256 -in message.txt -out encrypted.txt -recip client.pem -from server@ -to client@
