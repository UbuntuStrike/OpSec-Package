export RED='\033[1;91m'
export GREEN='\033[1;92m'

vm_install(){
echo "\n$RED You have chosen to install for a virtual machine! " $RESETCOLOR
mv ./proxy.sh ./proxy.sh.bak && cp vm.sh ./proxy.sh
}


regular_install(){
sleep 1
cp i2p.list /etc/apt/sources.list.d/i2p.list
apt update --allow-insecure-repositories
sleep 1
apt install i2p #tor privoxy macchanger nscd resolvconf dnsmasq i2pd net-tools bleachbit apt-transport-https lsb-release curl
sleep 1
mv /etc/privoxy/config /etc/privoxy/config.bak
cp config /etc/privoxy/config
sleep 1
mv /etc/tor/torrc /etc/tor/torrc.bak
sleep 1
cp torrc /etc/tor/torrc
sleep 1
rm /etc/apt/sources.list.d/i2p.list
sleep 1
chmod +x *.sh
sleep 1
echo ""
echo "" 
echo "\n$RED Your torrc file has been updated, original torrc file has been saved to /etc/tor/torrc.bak"
sleep 1
echo ""
echo "\n$RED your privoxy config file has been updated. original config file has been saved to config.bak"
sleep 1
echo ""
echo "\n$GREEN You can now run the OpSecTool by entering ./proxy.sh start"
}

case "$1" in
	vm)
		vm_install
		regular_install
	;;
	normal)
		regular_install
	;;
	*)
		echo "Usage: $0 {./install "vm" or "normal"}" >&2
		exit 3
	;;
esac

exit 0
