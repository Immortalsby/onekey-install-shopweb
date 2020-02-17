#!/bin/bash

set -o pipefail
#==========================================================
#       System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#       Description: Onekey-install for shopweb environment
#       Version: 0.0.1
#       Author: SHI Boyuan(boyuan.shi@hanshow.com)
#       Git: https://github.com/Immortalsby/onekey-install-shopweb
#       Website: boyuanshi.com
#==========================================================
# Some important notices:
# Before running this script, please make sure that mysql*.tar, jdk*.tar.gz, apache-tomcat*.tar.gz and start.sh are all in the same folder/path


# All variables needed
version=0.0.1
filepath=$(cd "$(dirname "$0")"; pwd)
jdk_folder="/usr/local/java"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"

# All funtions needed
check_root(){
        [[ $EUID != 0 ]] && echo -e "${Error} You are not having the root permission, please use${Green_background_prefix} su - ${Font_color_suffix}to change your current user to root." && exit 1
}

press_enter(){
		echo -e "\\033[0;32m\n\n"
		read -p "Press enter to continue (or ctrl+c to quit)"
		echo -e "\\033[0m"
}

install_mysql(){
        ## Install mysqld properly
		clear
		echo -e "\\033[0;32m====Starting install MYSQL====\033[0m"
		sleep 2s
		echo -e "\\033[0;32m====Checking existing of mariadb====\033[0m"
		sleep 2s
        maria=`rpm -qa | grep mariadb`
		if [ -z  "$maria" ];then
			echo -e "\\033[0;31mNo mariadb left\033[0m"
		else
			echo -e "\\033[0;31mMariadb detected\033[0m"
			rpm -e --nodeps $maria
			sleep 2s
			echo -e "\\033[0;31mMariadb removed\033[0m"
		fi
		echo -e "\\033[0;32m====Starting install mysql====\033[0m"
		sleep 2s
		tar -xvf mysql-* > /dev/null
		rpm -ivh *-common-* > /dev/null
		rpm -ivh *-libs-5* > /dev/null
		rpm -ivh *-client-5* > /dev/null
		rpm -ivh *-server-5* > /dev/null
		echo -e "\\033[0;32m====Starting service mysqld====\033[0m"
		sleep 1s
		service mysqld start
		echo -e "\\033[0;32m====Starting configuration MYSQL====\033[0m"
		sleep 1s
		read -p "New password for root(Press enter to use the default password: H@nshow123):" newpwd
		if [ -z "${newpwd}"];then
			newpwd="H@nshow123"
		fi
		echo
		echo -e "\\033[0;32mNew password for root is $newpwd\033[0m"
		passwd=`grep password /var/log/mysqld.log | cut -d: -f4 | cut -d' ' -f2 > /dev/null 2>&1`
		mysql -uroot -p$passwd --connect-expired-password -e "alter user 'root'@'localhost' identified by '$newpwd';" 
		read -p "Name of database that you want to creat(Press enter to use the default name: shopweb):" database
		if [ -z "${database}"];then
			database="shopweb"
		fi
		mysql -uroot -p$newpwd --connect-expired-password -e "create database if not exists $database default charset utf8;" 
		echo -e "\\033[0;32mDatabase $database has created\033[0m"
		read -p "The owner of database '$database'(For most situation just press enter to use user Root, if the user doesn't exist, it will be created):" usermysql
		if [ -z "${usermysql}"];then
			echo -e "\\033[0;32mThe owner of '$database' is root\033[0m"
		else
			read -p "Set password for mysql user '$usermysql'(Press enter to use default password 'H@nshow123'):" pwdmysql
			if [ -z "${newpwd}"];then
				pwdmysql="H@nshow123"
			fi
			mysql -uroot -p$newpwd --connect-expired-password -e "create user '$usermysql'@'localhost' identified by '$pwdmysql';" 
			mysql -uroot -p$newpwd --connect-expired-password -e "grant all privileges on $database.* to '$usermysql'@'localhost';" 
			mysql -uroot -p$newpwd --connect-expired-password -e "flush privileges;" 
		fi
		echo -e "\\033[0;33mAll done!\033[0m"
		press_enter
}

install_java(){
		echo -e "\\033[0;32mChecking if JAVA has already installed\033[0m"
		if ! [ -x  "$(command -v java)" ];then
			echo -e "\\033[0;32mNo JAVA exists, starting installation...\033[0m"
			sleep 2s
		else
			javav=`java -version`
			echo -e "\\033[0;31mA JAVA has already existed, please remove it before installation\033[0m\n\nQuiting"
			sleep 2s
			exit 1
		fi
		read -p "Enter the Fullpath for java(For most situations just press enter to use the default path: /usr/local/java):" javaurl
		if [ -z "${database}"];then
			javaurl="/usr/local/java"
			echo -e "\\033[0;31mJava will be install in $javaurl\033[0m"
		else
			echo -e "\\033[0;31mJava will be install in $javaurl\033[0m"
		fi
		mkdir -p $javaurl
		tar -zxvf jdk*.tar.gz -C $javaurl
		cd $javaurl
		javaname=`ls`
		javapath=$javaurl"/"$javaname
		echo -e "\\033[0;32m====Start Setting environment varaiables====\033[0m\n"
		echo "export JAVA_HOME=$javapath
		export JRE_HOME=\${JAVA_HOME}/jre 
		export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib 
		export PATH=\${JAVA_HOME}/bin:\$PATH" > /root/.bashrc
		source /root/.bashrc
		sleep 2s
		echo -e "\\033[0;33mAll done!\033[0m"
}

install_tomcat(){
		read -p "Enter the Fullpath for Tomcat(For most situations just press enter to use the default path: /data):" apacheurl
		if [ -z "${database}"];then
			apacheurl="/data"
			echo -e "\\033[0;31mTomcat will be install in $apacheurl\033[0m"
		else
			echo -e "\\033[0;31mTomcat will be install in $apacheurl\033[0m"
		fi
		tar -zxvf apache*.tar.gz -C $apacheurl
		cd $apacheurl
		apachename=`ls`
		apachepath=$apacheurl"/"$apachename
		cd $apachepath/bin
		tar -zxvf commons-daemon-native.tar.gz -C .
		cd commons-daemon-1.1.0-native-src/unix/
		./configure --with-java=$javapath
		make
		sleep 10s
		cp jsvc $apachepath/bin/
		cd $apachepath/bin
		read -p "Enter the MIN jvm memory for Tomcat(eg:1024)(Press enter to use the default memory: 1024):" minm
		if [ -z "${minm}"];then
			minm="1024"
		fi
		read -p "Enter the MAX jvm memory for Tomcat(eg:1024)(Press enter to use the default memory: 1024):" maxm
		if [ -z "${maxm}"];then
			maxm="1024"
		fi
		sed -i '/JAVA_HOME.*/c'"JAVA_HOME=$javapath" ./daemon.sh
		sed -i '/CATALINA_HOME.*/c'"CATALINE_HOME=$apachepath" ./daemon.sh
		sed -i '/CATALINA_BASE.*/c'"CATALINE_BASE=$apachepath" ./daemon.sh 
		sed -i '/TOMCAT_USER.*/c'"TOMCAT_USER=root" ./daemon.sh
		sed -i '/JAVA_OPTS.*/c'"JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\""
		echo -e "\\033[0;33mAll done!\033[0m"
}

check_env(){
		echo -e "\\033[0;31m====START CHECKING REQUIRED FILES====\033[0m\n"
		sleep 1s
		check_mysql=`ls -l | grep mysql*.tar`
		if [ -z  "$check_mysql" ];then
			echo -e "\\033[0;31mTar file mysql not found\033[0m"
			echo -e "\\033[0;31mPlease put all required files in the path\033[0m"
			exit 1
		fi
		check_java=`ls -l | grep jdk*.tar.gz`
		if [ -z  "$check_java" ];then
			echo -e "\\033[0;31mTar file jdk not found\033[0m"
			echo -e "\\033[0;31mPlease put all required files in the path\033[0m"
			exit 1
		fi
		check_apache=`ls -l | grep apache*.tar.gz`
		if [ -z  "$check_apache" ];then
			echo -e "\\033[0;31mTar file tomcat not found\033[0m"
			echo -e "\\033[0;31mPlease put all required files in the path\033[0m"
			exit 1
		fi
		echo -e "\\033[0;31mDone!\033[0m"
		sleep 1s
}

check_root
check_env
clear
echo -e "\\033[0;32m====Onekey-install-environment for shopweb (v$version)====\033[0m\nIf you find some bugs please contact boyuan.shi@hanshow.com (technical support)\n\n\n"
echo -e "\\033[0;31m[WARNING]Attention! All bad operations will destroy the system, please make 300% sure what you will do!\033[0m\n"
PS3='Please enter your choice: '
options=("Install MYSQL" "Install JAVA" "Install Tomcat" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install MYSQL")
            echo -e "\\033[0;31mYou chose choice $REPLY which is $opt\033[0m"
			press_enter	
			install_mysql
			sh ./start.sh
			break
	    	;;
        "Install JAVA")
            echo -e "\\033[0;31mYou chose choice $REPLY which is $opt\033[0m"
			press_enter
			install_java
			sh ./start.sh
            break
			;;
        "Install Tomcat")
            echo -e "\\033[0;31mYou chose choice $REPLY which is $opt\033[0m"
			press_enter
			install_tomcat
			sh ./start.sh
            break
			;;
        "Quit")
           	exit 1
            ;;
        *) echo -e "\\033[0;31mInvalid option $REPLY\033[0m";;
    esac
done