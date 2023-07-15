#!/bin/sh

#openssl cms -decrypt -secretkeyid 07 -secretkey 0123456789ABCDEF0123456789ABCDEF -in encrypted2.txt
openssl cms -decrypt -in encrypted.txt -inkey client.key -recip client.pem
