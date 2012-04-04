#!/bin/bash

#author: Bova Bovaev <ink08@ink-online.ru>
#
date_week=$(date -d "last-sun" +%F)
date_month=$(date -d "$(date +'%m/01') +1month -1day" +%F)


PROJNAME="domain" #Имя проекта
CHARSET="utf8" #Кодировка базы данных (utf8)
DBNAME="${PROJNAME}_db" #Имя базы данных для резервного копирования
DBFILENAME="${PROJNAME}_cms" #Имя дампа базы данных
ARFILENAME="${PROJNAME}_files" #Имя архива с файлами
HOST="localhost" #Хост MySQL
USER="root" #Имя пользователя базы данных
PASSWD="CLErYSTxGNIeqcCTatxF2Zk" #Пароль от базы данных
TARSPARSEDIR="/mnt/backups/$PROJNAME/tmp" #разностные бекапы tar
TARSPARSEFILE="$TARSPARSEDIR/`date -d '-1 day' +%m.%d`"
TARSPARSEMONTH="$TARSPARSEDIR/`date -d '-1 day' +%m`"
EVERYDAYDIR="/mnt/backups/$PROJNAME/everyday"
WEEKDIR="/mnt/backups/$PROJNAME/week"
MONTHDIR="/mnt/backups/$PROJNAME/month"
SRCFILES="/var/www/$PROJNAME" #Путь к каталогу файлов для архивирования
SRCFILES2="/etc"
SRCFILES3="/usr/local/ispmgr"
PREFIX=$(date -d "-1 day" +%F) #Префикс по дате для структурирования резервных копий

DATADIR=$EVERYDAYDIR
if [[ $PREFIX == $date_week ]]
then
    DATADIR=$WEEKDIR
fi

if [[ $PREFIX == $date_month ]]
then
    rm -f $TARSPARSEDIR/*
fi
LOGS="$DATADIR/$PREFIX/log.txt"

mkdir -p $TARSPARSEDIR 2> /dev/null

mkdir -p $WEEKDIR 2> /dev/null
mkdir -p $MONTHDIR 2> /dev/null

# set type backup
BACKUP_TYPE="full"
if [ -f $TARSPARSEMONTH ]
then
  cp $TARSPARSEMONTH $TARSPARSEFILE
  BACKUP_TYPE="diff"
else
  TARSPARSEFILE=$TARSPARSEMONTH
  DATADIR=$MONTHDIR
fi

mkdir -p $DATADIR/$PREFIX 2> /dev/null

#start backup

echo "[--------------------------------[`date +%F--%H-%M`]--------------------------------]" | tee $LOGS
echo "[----------][`date +%F--%H-%M`] Run the backup script..." | tee -a $LOGS
echo "[+---------][`date +%F--%H-%M`] Delete old backups..." | tee -a $LOGS
find $DATADIR -type d -mtime +7 -print0 | xargs -0 rm -rf
find $WEEKDIR -type d -mtime +30 -print0 | xargs -0 rm -rf
find $MONTHDIR -type d -mtime +60 -print0 | xargs -0 rm -rf
echo "[++--------][`date +%F--%H-%M`] Generate a database backup..." | tee -a $LOGS
#MySQL dump
mysqldump --user=$USER --host=$HOST --password=$PASSWD -R -f --default-character-set=$CHARSET $DBNAME | gzip -c > $DATADIR/$PREFIX/$DBFILENAME-`date +%F--%H-%M`.sql.gz
if [[ $? -gt 0 ]];then
echo "[++--------][`date +%F--%H-%M`] Aborted. Generate database backup failed." | tee -a $LOGS
exit 1
fi
echo "[++++------][`date +%F--%H-%M`] Backup database [$DBNAME] - successfull." | tee -a $LOGS
echo "[++++++----][`date +%F--%H-%M`] Copy the source code project [$PROJNAME]..." | tee -a $LOGS
#Src dump

tar -g $TARSPARSEFILE -czpf $DATADIR/$PREFIX/$ARFILENAME-`date +%F--%H-%M`_$BACKUP_TYPE.tar.gz $SRCFILES $SRCFILES2 $SRCFILES3 2> /dev/null
if [[ $? -gt 0 ]];then
echo "[++++++----][`date +%F--%H-%M`] Aborted. Copying the source code failed." | tee -a $LOGS
exit 1
fi
echo "[++++++++--][`date +%F--%H-%M`] Copy the source code project [$PROJNAME] successfull." | tee -a $LOGS
echo "[+++++++++-][`date +%F--%H-%M`] Free HDD space: `df -h /mnt/backups|tail -n1|awk '{print $4}'`" | tee -a $LOGS
echo "[++++++++++][`date +%F--%H-%M`] All operations completed successfully!" | tee -a $LOGS


#delete old tar sparse files
find $TARSPARSEDIR -type f -iname "`date -d '-1 day' +%m`\.*" -print0 | xargs -0 rm -f

# mirror to ftp
#/etc/scripts/mirror_to_ftp.sh
