#!/bin/sh

openssl cms -encrypt -in message.txt -aes256 -binary -out encrypted.txt client.pem
