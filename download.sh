# /bin/bash

pr_red() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ={1..500})"
	  printf '\033[0;31m%*.*s %s %*.*s\n\033[0m' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}
check_root(){
        [[ $EUID != 0 ]] && pr_red "[Error]" && echo -e "You are not having the root permission, please use su - to change your current user to root." && exit 1
}
check_root
yum -y install git
git clone https://github.com/Immortalsby/onekey-install-shopweb.git
cp ./onekey-install-shopweb/install_v* /bin/hanshow
cp ./onekey-install-shopweb/update.sh /bin/hanshowup
chmod 775 /bin/hanshow
chmod 775 /bin/hanshowup

rm -rf ./onekey-install-shopweb
echo
echo
pr_red "Program has been insalled"
echo
pr_red "If you dont want to run it this time"
echo
pr_red "Next time you can run command 'hanshowup' for newest version"
echo
pr_red "Go to the path where all packages in"
echo
pr_red "Then you can run 'hanshow'"
