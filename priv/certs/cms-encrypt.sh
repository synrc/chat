#!/bin/sh

#openssl cms -encrypt -secretkeyid 07 -secretkey 0123456789ABCDEF0123456789ABCDEF -aes256 -in message.txt -out encrypted2.txt
openssl cms -encrypt -aes256 -in message.txt -out encrypted.txt -recip client.pem -keyopt ecdh_kdf_md:sha256
