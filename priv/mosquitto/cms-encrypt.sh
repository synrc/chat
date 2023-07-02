#!/bin/sh

openssl cms -encrypt -in message.txt -aes256 -out encrypted.txt client.bun

