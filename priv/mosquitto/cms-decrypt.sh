#!/bin/sh

openssl cms -decrypt -in encrypted.txt -recip client.bun

