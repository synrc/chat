#!/bin/sh

# Expect "CMS Verification successful"
openssl cms -verify -CAfile caroot.pem -in signature.txt -signer client.pem -out verified.txt
