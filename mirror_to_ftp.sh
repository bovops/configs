#!/bin/bash

#author: Bova Bovaev <ink08@ink-online.ru>
#

FTP_HOST="host"
FTP_USER="user"
FTP_PASS="password"

lftp -e 'mirror --reverse --delete-first /mnt/backups /backups; bye;' -u $FTP_USER,$FTP_PASS $FTP_HOST
