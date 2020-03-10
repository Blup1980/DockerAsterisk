#!/bin/sh
docker build --pull --build-arg http_proxy --build-arg https_proxy -t blup1980/asterisk .

