#!/bin/bash

set -o pipefail
#==========================================================
#       System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+
#       Description: Onekey-install for shopweb environment
#       Version: 0.0.2
#       Author: SHI Boyuan(boyuan.shi@hanshow.com)
#       Git: https://github.com/Immortalsby/onekey-install-shopweb
#       Website: boyuanshi.com
#==========================================================
# Some important notices:
# Before running this script, please make sure that mysql*.tar, jdk*.tar.gz, apache-tomcat*.tar.gz and start.sh are all in the same folder/path


# All variables needed
version=0.0.2
filepath=$(pwd)

#echo $filepath
#sleep 10s

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
		pr_green "Start installing MYSQL"
		sleep 2s
		pr_green "Checking if Mariadb packages have already installed"
		do_ing
		pr_red "[WARNING]The list will not be upgrade when you deleted packages"
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
			pr_green "No mariadb left"
		else
			pr_red "Mariadb detected, make sure that you want to continue!"
		fi
		press_enter
		pr_red "Start installing mysql"
		sleep 1s
		pr_red "Unzipping file"
		do_ing
		tar -xvf mysql-* > /dev/null
		pr_red "Installing Mysql 5.*.*"
		rpm -ivh *-common-* > /dev/null
		rpm -ivh *-libs-5* > /dev/null
		rpm -ivh *-client-5* > /dev/null
		rpm -ivh *-server-5* > /dev/null
		do_ing
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
		passwd=`grep "A temporary password is generated for root@localhost:" /var/log/mysqld.log | awk -F'localhost: ' '{print $2}'`
		mysql -uroot -p$passwd --connect-expired-password -e "alter user 'root'@'localhost' identified by '$newpwd';
		quit" 
		do_ing
		read -p "Database name(Press enter to use the default name: shopweb):" database
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
		pr_red "Deleting all rpm files"
		do_ing
		rm -rf mysql*.rpm
		pr_green "All done!"
}

install_java(){	
		clear
		pr_green "Start installing JAVA"
		sleep 1s
		pr_green "Checking if JAVA packages have already installed"
		pr_red "[WARNING]The list will not be upgrade when you deleted packages"
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
		pr_red "Looking for remaining JAVA packages"
		rpm -qa | grep java
		pr_red "Make sure that you want to continue"
		press_enter
		pr_red "Checking if JAVA has already installed"
		sleep 1s
		do_ing
		if ! [ -x  "$(command -v java)" ];then
			pr_green "No JAVA exists, starting installation"
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
		tar -zxvf jdk*.tar.gz -C $javaurl > /dev/null
		cd $javaurl
		javaname=`ls`
		javapath=$javaurl"/"$javaname
		do_ing
		pr_red "Start Setting environment varaiables"
		echo "export JAVA_HOME=${javapath}
export JRE_HOME=\${JAVA_HOME}/jre
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib
export PATH=\${JAVA_HOME}/bin:\$PATH" >> /root/.bashrc
		source /root/.bashrc
		sleep 1s
		do_ing
		cd $filepath
		pr_green "All done!"
}

install_app(){
		clear
		pr_red "Start installing Tomcat"
		if ! [ -x  "$(command -v java)" ];then
			pr_green "No JAVA exists, quiting"
			sleep 1s
			pr_red "Quiting"
			do_ing
			sleep 1s
			exit 1
		fi
		sleep 2s
		read -p "Enter the Fullpath for Tomcat(For most situations just press enter to use the default path: /data/hanshow):" apacheurl
		if [ -z "${apacheurl}" ];then
			apacheurl="/data/hanshow"
			pr_red "Tomcat will be install in $apacheurl"
		else
			pr_red "Tomcat will be install in $apacheurl"
		fi
		pr_red "Unzipping file"
		mkdir -p $apacheurl
		tar -zxvf apache*.ta* -C $apacheurl > /dev/null
		do_ing
		pr_red "Installing Tomcat"
		cd $apacheurl
		apachename=`ls`
		apachepath=$apacheurl"/"$apachename
		cd $apachepath/bin
		tar -zxvf commons-daemon-native.tar.gz -C . > /dev/null
		cd commons-daemon-*native-src/unix/
		source /root/.bashrc
		javapathwithbin=`which java`
		javapath=${javapathwithbin%/*}
		javap=${javapath%/*}
		echo $javap
		./configure --with-java=$javap
		make
		cp jsvc $apachepath/bin/
		cd $apachepath/bin
		read -p "Enter the MIN jvm memory for Tomcat(eg:1024)(Press enter to use the default memory: 1024):" minm
		if [ -z "${minm}" ];then
			minm="1024"
		fi
		read -p "Enter the MAX jvm memory for Tomcat(eg:1024)(Press enter to use the default memory: 1024):" maxm
		if [ -z "${maxm}" ];then
			maxm="1024"
		fi
		chkconf="#chkconfig:2345 10 90"
		javahome="JAVA_HOME=$javap"
		catahome="CATALINA_HOME=$apachepath"
		tomuser="TOMCAT_USER=root"
		#sed -i '/JAVA_OPTS=/c'"JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"" ./daemon.sh
		sed -i "0,/JAVA_OPTS=/s//JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"/" ./daemon.sh
		sed -i "N;2a$tomuser" ./daemon.sh
		sed -i "N;2a$catahome" ./daemon.sh
		sed -i "N;2a$javahome" ./daemon.sh
		sed -i "N;2a$chkconf" ./daemon.sh
		pr_red "Setting shopweb as service"
		do_ing
		cp daemon.sh /etc/init.d/shopweb
		chmod 755 /etc/init.d/shopweb
		chkconfig --add shopweb
		pr_red "Start shopweb service"
		service shopweb start
		pr_green "Service shopweb started"
		cd $filepath
		pr_red "Setting"
		do_ing
		pr_green "Done"
		pr_red "Will you install Shopweb?"
		echo
		press_enter
		pr_red "Check if shopweb exists"
		ifshop=`ls | grep shopweb*`
		if [ -z  "$ifshop" ];then
			pr_red "Shopweb not found"
			pr_red "Skipping"
			do_ing
		else
			pr_green "Shopweb found"
			if [ $ifshop == "shopweb.war" ];then
				cp shopweb.war $apachepath/webapps/
			else
				cp -r $ifshop $apachepath/webapps/shopweb
			fi
			pr_red "Install Shopweb"
			do_ing
			pr_green "Done!"
			sleep 1s
		fi
		pr_red "Will you install Eslworking?"
		echo
		press_enter
		pr_red "Check if eslworking exists"
		ifesl=`ls | grep eslworking*`
		if [ -z  "$ifesl" ];then
			pr_red "Esl-working not found"
			pr_red "Skipping"
			do_ing
		else
			pr_green "Esl-working found"
			read -p "Enter the Fullpath for Esl-working(Press enter to use the default path: /data/store):" eslurl
			if [ -z "${eslurl}" ];then
				eslurl="/data/store"
			fi
			mkdir -p $eslurl
			pr_red "Intalling ESL-Working"
			do_ing
			if [[ $ifesl == eslworking*.zip ]];then
				yum -y install unzip
				unzip $ifesl -d $eslurl > /dev/null
				pr_red "You need configure Esl-working yourself"
			elif [[ $ifesl == eslworking*.tar ]];then
				tar -xvf $ifesl -C $eslurl > /dev/null
			elif [[ $ifesl == eslworking*.7z ]];then
				yum -y install epel-release	
				yum -y install p7zip
				7za x $ifesl -r -o$eslurl/
			else
				cp -r $ifesl $eslurl/
			fi
			cd $eslurl
			eslname=`ls | grep esl*`
			cd $eslname
			eslv=`ls | grep users`
			if [[ $eslv == users ]];then
				pr_red "Detected ESL version: 3.0.*"
				do_ing
				sleep 1s
				pr_green "Create ESL Database"
				read -p "Enter the MYSQL password(Press enter to use default password: H@nshow123):" eslpwd
				if [ -z "${eslpwd}" ];then
					eslpwd="H@nshow123"
				fi
				mysql -uroot -p$eslpwd --connect-expired-password -e "create database if not exists eslworking default charset utf8;" 
				sed -i "0,/jdbc.host={server_host}/s//jdbc.host=localhost/" ${eslurl}/eslworkin*/config/jdbc.properties
				sed -i "0,/jdbc.username={username}/s//jdbc.username=root/" ${eslurl}/eslworkin*/config/jdbc.properties
				sed -i "0,/jdbc.password={password}/s##jdbc.password=${eslpwd}#" ${eslurl}/eslworkin*/config/jdbc.properties
			else
				pr_red "Detected ESL version: 2.*.*"
			fi
			cd $filepath
			pr_red "Configuring eslworking.sh"
			do_ing
			#sed -i '/JAVA_OPTS=/c'"JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"" ./daemon.sh
			#sed -i "0,/JAVA_OPTS=/s//JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"/" ./daemon.sh
			sed -i "0,/JAVA_HOME=/s##JAVA_HOME=$javap#" ${eslurl}/eslworkin*/bin/eslworking.sh
			sed -i "0,/APP_HOME=/s##APP_HOME=${eslurl}\/${eslname}#" ${eslurl}/eslworkin*/bin/eslworking.sh
			appuser="APP_USER=root"
			sed -i "0,/APP_USER=/s//${appuser}/" ${eslurl}/eslworkin*/bin/eslworking.sh
			read -p "Enter the MIN jvm memory for Eslworking(eg:1024)(Press enter to use the default memory: 1024):" minm
			if [ -z "${minm}" ];then
				minm="1024"
			fi
			read -p "Enter the MAX jvm memory for Eslworking(eg:1024)(Press enter to use the default memory: 1024):" maxm
			if [ -z "${maxm}" ];then
				maxm="1024"
			fi
			sed -i '/JAVA_OPTS=\"/c'"JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"" ${eslurl}/eslworkin*/bin/eslworking.sh
			#sed -i "0,/JAVA_OPTS=*/s//JAVA_OPTS=\"-Xms${minm}m -Xmx${maxm}m\"/" ${eslurl}/eslworkin*/bin/eslworking.sh
			cp ${eslurl}/eslworkin*/bin/eslworking.sh /etc/init.d/eslworking
			chkconfig --add eslworking
			pr_red "Changing right owner and privilleges"
			chown root:root -R $eslurl
			chown root:root -R $apacheurl
			chmod 755 -R $eslurl
			chmod 755 -R $apacheurl	
			chmod 755 /etc/init.d/eslworking
			do_ing
			sleep 1s
			pr_green "Done!"
			pr_red "Start eslworking service"
			sudo service eslworking start
			pr_green "Service eslworking started"
		fi
		pr_red "Install Integration is not supported"
		pr_red "= = = = = = = = = = = = = = "
		pr_red "Please intall it manually"
		service eslworking stop
		service eslworking start
		pr_green "All done!"
}

check_env(){
		pr_red "START CHECKING REQUIRED FILES"
		do_ing 
		sleep 1s
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
		echo
		pr_green "OK!"
		sleep 1s
}
clear
pr_red "Checking root permission"
do_ing
check_root
echo
pr_green "OK"
echo
echo
echo
check_env
echo
echo
pr_green "Program starts in 3s..."
echo
sleep 1s
pr_green "Program starts in 2s..."
echo
sleep 1s
pr_green "Program starts in 1s..."
echo
sleep 1s
clear
pr_red "= = = = = = = = = = = = = = = = = = = = = = = = = ="
pr_red "= = = = = = = = = = = = = = = = = = = = = = = = = ="
pr_red "Onekey-install-environment for shopweb (v$version)"
pr_red "= = = = = = = = = = = = = = = = = = = = = = = = = ="
pr_red "= = = = = = = = = = = = = = = = = = = = = = = = = ="
echo
pr_green "If you find some bugs please contact boyuan.shi@hanshow.com (technical support)"
echo
echo
echo
echo -e "\\033[0;31m[WARNING]Attention! All bad operations will destroy the system, please make 300% sure what you will do!\033[0m\n"
echo
PS3='Please enter your choice: '
options=("Install MYSQL" "Install JAVA" "Install Applications" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install MYSQL")
            pr_red "You chose choice $REPLY which is $opt"
			press_enter	
			install_mysql
			press_enter
			sh $0
			break
	    	;;
        "Install JAVA")
            pr_red "You chose choice $REPLY which is $opt"
			press_enter
			install_java
			press_enter
			sh $0
			break
			;;
        "Install Applications")
            pr_red "You chose choice $REPLY which is $opt"
			press_enter
			install_app
			press_enter
			sh $0
			break
			;;
        "Quit")
           	exit 1
            ;;
        *) pr_red "Invalid option $REPLY";;
    esac
done
