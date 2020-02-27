pr_red() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ={1..500})"
	  printf '\033[0;31m%*.*s %s %*.*s\n\033[0m' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}
echo "Check new version..."
git clone https://github.com/Immortalsby/onekey-install-shopweb.git
cp ./onekey-install-shopweb/install_v* /bin/hanshow
cp ./onekey-install-shopweb/update.sh /bin/hanshowup
chmod 775 /bin/hanshow
chmod 775 /bin/hanshowup
rm -rf ./onekey-install-shopweb
echo "Done!"
