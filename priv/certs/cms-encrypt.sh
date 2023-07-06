#!/bin/sh

openssl cms -encrypt -aes256 -in message.txt -out encrypted.txt -recip client.pem -keyopt ecdh_kdf_md:sha256 -keyopt ecdh_cofactor_mode:0
