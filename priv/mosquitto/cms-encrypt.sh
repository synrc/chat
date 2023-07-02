#!/bin/sh

openssl cms -encrypt -in message.txt -binary -out encrypted.txt client.pem
