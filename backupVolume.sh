#!/bin/sh

docker run --rm --volumes-from asterisk -v $(pwd):/backup ubuntu tar cvf /backup/backupAsterisk.tar /etc/asterisk
