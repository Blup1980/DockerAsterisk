#!/bin/sh
docker run -d -v ./etc/asterisk:/etc/asterisk -v ./sounds:/var/lib/asterisk/sounds --network host --restart always blup1980/asterisk:20.4
