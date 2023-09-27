#!/bin/sh

docker run --rm --volumes-from asterisk -v $(pwd):/backup ubuntu tar --overwrite -xvf /backup/backupAsterisk.tar -C /etc/asterisk
