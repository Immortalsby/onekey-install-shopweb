#!/bin/bash

# Important: This backup tools is made for systemU, other stores may not compatible

# Core config info
mysql_user="root"
mysql_password="H@nshow123"
mysql_host="localhost"
mysql_port="3306"
mysql_charset="utf8"
db_shopweb="shopweb"
db_eslworking="eslworking"
backup_location=/hanshow/backup
history_location=/hanshow/archive
expire_backup_delete="ON"
expire_days=7

# The PATH where Tomcat and Integraion are
appurl=/hanshow/store

# Config info
backup_time=`date +%Y%m%d%H%M`
backup_Ymd=`date +%Y-%m-%d`
backup_3ago=`date -d '7 days ago' +%Y-%m-%d`
backup_dir=$backup_location/$backup_Ymd
welcome_msg="Welcome to use HANSHOW backup tools!"

# Mysql config info
mysql_ps=`ps -ef |grep mysql |wc -l`
mysql_listen=`netstat -an |grep LISTEN |grep $mysql_port|wc -l`
if [ [$mysql_ps == 0] -o [$mysql_listen == 0] ]; then
        echo "ERROR:MySQL is not running! backup stop!"
        exit
else
        echo $welcome_msg
fi

# start mysql connection
mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password <<end
use mysql;
select host,user from user where user='root' and host='localhost';
exit
end
flag=`echo $?`
if [ $flag != "0" ]; then
        echo "ERROR:Can't connect mysql server! backup stop!"
        exit
else
        echo "MySQL connect ok! Please wait......"
        echo "database $db_shopweb backup start..."
        ifexist=`ls $backup_location/`
        if [ -z "$ifexist" ];then
           echo "No backup file find"
        else
           cp -r $backup_location/* $history_location/
           rm -rf $backup_location/*
        fi
        `mkdir -p $backup_dir`
        `mysqldump -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password $db_shopweb --default-character-set=$mysql_charset --tables hs_store hs_config hs_goods_esl_pr hs_ap | gzip > $backup_dir/$db_shopweb-$backup_time.sql.gz`
        flag=`echo $?`
        if [ $flag == "0" ];then
           echo "database $db_shopweb success backup to $backup_dir/$db_shopweb-$backup_time.sql.gz"
        else
           echo "database $db_shopweb backup fail!"
        fi
        echo "database $db_eslworking backup start"
        `mysqldump -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password $db_eslworking --default-character-set=$mysql_charset --tables t_esl t_ap t_esl_binding_status | gzip > $backup_dir/$db_eslworking-$backup_time.sql.gz`
        flag=`echo $?`
        if [ $flag == "0" ];then
           echo "database $db_eslworking success backup to $backup_dir/$db_eslworking-$backup_time.sql.gz"
        else
           echo "database $db_eslworking backup fail!"
        fi
        ifconfiginte=`find $appurl -name Hanshow-Integration* -type d`
        ifconfigapi=`find $appurl -name webapps -type d`
        if [ -z "$ifconfiginte" ];then
           echo "Can not find Integration configuration file in $ifconfiginte"
        else
           cp $ifconfiginte/config.properties $backup_dir
           echo "Find in $ifconfiginte"
           echo "Backup Integration configuration file success"
        fi
        if [ -z "$ifconfigapi" ];then
           echo "Can not find apieeg configuration file in $ifconfiginte"
        else
           cp $ifconfigapi/api-eeg/WEB-INF/classes/application.properties $backup_dir
           echo "Find in $ifconfigapi"
           echo "Backup Integration configuration file success"
        fi
        if [ "$expire_backup_delete" == "ON" -a  "$backup_location" != "" ];then
                 #`find $backup_location/ -type d -o -type f -ctime +$expire_days -exec rm -rf {} \;`
                 `find $history_location/ -type d -mtime +$expire_days | xargs rm -rf`
                 echo "Expired backup data delete complete!"
        fi
        echo "All database and files backup success! Thank you!"
        exit
fi
