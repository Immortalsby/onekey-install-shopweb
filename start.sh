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

# All funtions needed
check_root(){
        [[ $EUID != 0 ]] && pr_red "[Error]" && echo -e "You are not having the root permission, please use su - to change your current user to root." && exit 1
}

pr_red() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ={1..500})"
  printf '\033[0;31m%*.*s %s %*.*s\n\033[0m' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

pr_green() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ={1..500})"
  printf '\033[0;32m%*.*s %s %*.*s\n\033[0m' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

do_ing() {
	b=''
	i=0
	while [ $i -le 100 ]
	do
		printf "\033[0;34m[%-50s] %d%% \r\033[0m" "$b" "$i";
		usleep 30000
		((i=i+2))
		b+='#'
	done
	echo
}
press_enter(){
		read -p "Press enter to continue (or ctrl+c to quit)"
}

install_mysql(){
		clear
		pr_red "Start installing MYSQL"
		sleep 2s
		pr_red "Checking if Mariadb packages have already installed"
		do_ing
		PS3='Please enter which Mariadb package(s) you want to delete: '
		c=0
		for pack in `rpm -qa | grep mariadb`
		do
			packlist[$c]=$pack
			((c++))
		done
		packlist[$c]="Quit"
		echo
		select pk in "${packlist[@]}"
		do
            		case $pk in
				"Quit")
					pr_green "All done!"
					break
				;;
				*)
					pr_red "$pk will be deleted"
					press_enter	
					rpm -e --nodeps $pk
					pr_red "Deleting $pk"
					sleep 1s
					do_ing
					pr_green "Done!"
				;;
			esac
		done
		sleep 2s
		pr_red "Checking exist of mariadb"
		sleep 1s
		do_ing
		if [ -z  "$maria" ];then
			pr_red "No mariadb left"
		else
			pr_red "Mariadb detected, make sure that you want to continue!"
		fi
		press_enter
		pr_red "Start installing mysql"
		sleep 1s
		pr_red "Unzipping file"
		do_ing
		tar -xvf mysql-* > /dev/null
		pr_red "Installing Mysql"
		do_ing
		rpm -ivh *-common-* > /dev/null
		rpm -ivh *-libs-5* > /dev/null
		rpm -ivh *-client-5* > /dev/null
		rpm -ivh *-server-5* > /dev/null
		pr_green "Done!"
		sleep 1s
		pr_red "Starting service mysqld"
		service mysqld start
		do_ing
		pr_red "Starting configuration MYSQL"
		sleep 1s
		read -p "New password for root(Press enter to use the default password: H@nshow123):" newpwd
		if [ -z "${newpwd}"];then
			newpwd="H@nshow123"
		fi
		echo
		pr_red "New password for root is $newpwd"
		passwd=`grep password /var/log/mysqld.log | cut -d: -f4 | cut -d' ' -f2 > /dev/null 2>&1`
		mysql -uroot -p$passwd --connect-expired-password -e "alter user 'root'@'localhost' identified by '$newpwd';" 
		do_ing
		read -p "Name of database that you want to creat(Press enter to use the default name: shopweb):" database
		if [ -z "${database}"];then
			database="shopweb"
		fi
		mysql -uroot -p$newpwd --connect-expired-password -e "create database if not exists $database default charset utf8;" 
		do_ing
		pr_red "Database $database has created"
		read -p "The owner of database '$database'(For most situation just press enter to use user Root. Otherwise if user doesn't exist, it will be created):" usermysql
		if [ -z "${usermysql}"];then
			pr_red "The owner of '$database' is root."
		else
			read -p "Set password for mysql user '$usermysql'(Press enter to use default password 'H@nshow123'):" pwdmysql
			if [ -z "${newpwd}"];then
				pwdmysql="H@nshow123"
			fi
			mysql -uroot -p$newpwd --connect-expired-password -e "create user '$usermysql'@'localhost' identified by '$pwdmysql';" 
			mysql -uroot -p$newpwd --connect-expired-password -e "grant all privileges on $database.* to '$usermysql'@'localhost';" 
			mysql -uroot -p$newpwd --connect-expired-password -e "flush privileges;" 
		fi
		do_ing
		pre_green "All done!"
		press_enter
}

install_java(){	
		clear
		pr_red "Start installing JAVA"
		sleep 1s
		pr_red "Checking if JAVA packages have already installed"
		PS3='Please enter which java package(s) you want to delete: '
		c=0
		for pack in `rpm -qa | grep java`
		do
			packlist[$c]=$pack
			((c++))
		done
		packlist[$c]="Quit"
		echo
		select pk in "${packlist[@]}"
		do
            		case $pk in
				"Quit")
					pr_green "All done!"
					break
				;;
				*)
					pr_red "$pk will be deleted"
					press_enter	
					rpm -e --nodeps $pk
					pr_red "Deleting $pk"
					sleep 1s
					do_ing
					pr_green "Done!"
				;;

			esac
		done
		press_enter
		pr_red "Checking if JAVA has already installed"
		sleep 1s
		do_ing
		if ! [ -x  "$(command -v java)" ];then
			pr_red "No JAVA exists, starting installation"
			sleep 2s
		else
			javav=`java -version`
			pr_red "A JAVA has already existed, please remove it before installation"
			sleep 1s
			pr_red "Quiting"
			do_ing
			sleep 1s
			exit 1
		fi
		read -p "Enter the Fullpath for java(For most situations just press enter to use the default path: /usr/local/java):" javaurl
		if [ -z "${javaurl}"];then
			javaurl="/usr/local/java"
		fi
		pr_red "Java will be install in $javaurl"
		sleep 1s
		pr_red "Installing JAVA"
		mkdir -p $javaurl
		tar -zxvf jdk*.tar.gz -C $javaurl
		cd $javaurl
		javaname=`ls`
		javapath=$javaurl"/"$javaname
		do_ing
		pr_red "Start Setting environment varaiables"
		echo "export JAVA_HOME=$javapath
		export JRE_HOME=\${JAVA_HOME}/jre 
		export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib 
		export PATH=\${JAVA_HOME}/bin:\$PATH" > /root/.bashrc
		source /root/.bashrc
		sleep 1s
		do_ing
		pr_green "All done!"
}

install_tomcat(){
		clear
		pr_red "Start installing Tomcat"
		sleep 2s
		read -p "Enter the Fullpath for Tomcat(For most situations just press enter to use the default path: /data):" apacheurl
		if [ -z "${database}"];then
			apacheurl="/data"
			pr_red "Tomcat will be install in $apacheurl"
		else
			pr_red "Tomcat will be install in $apacheurl"
		fi
		pr_red "Unzipping file"
		tar -zxvf apache*.tar.gz -C $apacheurl
		do_ing
		pr_red "Installing Tomcat"
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
		sed -i '/JAVA_OPTS.*/c'"JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"" ./daemon.sh
		cd $filepath
		pr_red "Setting"
		do_ing
		pr_green "All done!"
}

check_env(){
		pr_red "START CHECKING REQUIRED FILES"
		do_ing 
		sleep 2s
		check_mysql=`ls -l | grep mysql*.tar`
		if [ -z  "$check_mysql" ];then
			pr_red "Tar file mysql not found"
			pr_red "Please put all required files in the path"
			exit 1
		fi
		check_java=`ls -l | grep jdk*.tar.gz`
		if [ -z  "$check_java" ];then
			pr_red "Tar file jdk not found"
			pr_red "Please put all required files in the path"
			exit 1
		fi
		check_apache=`ls -l | grep apache*.tar.gz`
		if [ -z  "$check_apache" ];then
			pr_red "Tar file tomcat not found"
			pr_red "Please put all required files in the path"
			exit 1
		fi
		pr_green "OK!"
		sleep 2s
		press_enter
}
clear
pr_red "Checking root permission"
do_ing
check_root
sleep 1s
pr_green "OK"
check_env
clear
pr_red "Onekey-install-environment for shopweb (v$version)"
echo
pr_green "If you find some bugs please contact boyuan.shi@hanshow.com (technical support)"
echo
echo
echo
echo -e "\\033[0;31m[WARNING]Attention! All bad operations will destroy the system, please make 300% sure what you will do!\033[0m\n"
echo
PS3='Please enter your choice: '
options=("Install MYSQL" "Install JAVA" "Install Tomcat" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install MYSQL")
            pr_red "You chose choice $REPLY which is $opt"
			press_enter	
			install_mysql
			press_enter
			sh ./start.sh
			break
	    	;;
        "Install JAVA")
            pr_red "You chose choice $REPLY which is $opt"
			press_enter
			install_java
			press_enter
			sh ./start.sh
            break
			;;
        "Install Tomcat")
            pr_red "You chose choice $REPLY which is $opt"
			press_enter
			install_tomcat
			press_enter
			sh ./start.sh
            break
			;;
        "Quit")
           	exit 1
            ;;
        *) pr_red "Invalid option $REPLY";;
    esac
done
