#!/bin/sh

openssl cms -decrypt -in encrypted.txt -inkey client.key -recip client.pem
