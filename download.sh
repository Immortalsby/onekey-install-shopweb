yum -y install git
git clone https://github.com/Immortalsby/onekey-install-shopweb.git
cp ./onekey-install-shopweb/install* ./
pr_red() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ={1..500})"
	  printf '\033[0;31m%*.*s %s %*.*s\n\033[0m' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

pwd=`pwd`
echo
echo
pr_red "Make sure you get all files needed in ${pwd}"
echo
pr_red "Then you can run 'sh install_v*.sh'"
