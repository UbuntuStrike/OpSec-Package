#!/bin/sh
export GREEN='\033[1;94m'
export GREEN='\033[1;92m'
export RED='\033[1;91m'
export RESETCOLOR='\033[1;00m'
# Coded by ~an0nsec666
# List, separated by spaces, of destinations that you do not want to be
# routed through Tor
NON_TOR="192.168.0.0/16 172.16.0.0/12"

# The UID as which Tor runs
TOR_UID="debian-tor"

# Tor TransPort
TRANS_PORT="9040"

# List, separated by spaces, of process names that should be killed
TO_KILL="chrome dropbox firefox pidgin skype thunderbird xchat hexchat transmission"

# List, separated by spaces, of BleachBit cleaners
BLEACHBIT_CLEANERS="bash.history system.cache system.clipboard system.custom system.recent_documents system.rotated_logs system.tmp system.trash"

# Overwrite files to hide contents
OVERWRITE="true"

# The default local hostname
REAL_HOSTNAME="anonbox"

ask() {
	while true; do
		if [ "${2:-}" = "Y" ]; then
			prompt="Y/n"
			default=Y
		elif [ "${2:-}" = "N" ]; then
			prompt="y/N"
			default=N
		else
			prompt="y/n"
			default=
		fi
 
		echo
		read -p "$1 [$prompt] > " REPLY
 
		if [ -z "$REPLY" ]; then
			REPLY=$default
		fi
 
		case "$REPLY" in
			Y*|y*) return 0 ;;
			N*|n*) return 1 ;;
		esac
	done
}

# Make sure that only root can run this script
check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "\n[!] This script must run as root\n" >&2
		exit 1
	fi
}

kill_process() {
	if [ "$TO_KILL" != "" ]; then
		killall -q $TO_KILL
		echo " * Killed processes to prevent leaks"
	fi
}

clean_dhcp() {
	dhclient -r
	rm -f /var/lib/dhcp/dhclient*
	echo " * DHCP address released"
}

change_hostname() {
	
	echo

	CURRENT_HOSTNAME=$(hostname)

	clean_dhcp

	RANDOM_HOSTNAME=$(shuf -n 1 /etc/dictionaries-common/words | sed -r 's/[^a-zA-Z]//g' | awk '{print tolower($0)}')

	NEW_HOSTNAME=${1:-$RANDOM_HOSTNAME}

	echo "$NEW_HOSTNAME" > /etc/hostname
	sed -i 's/127.0.1.1.*/127.0.1.1\t'"$NEW_HOSTNAME"'/g' /etc/hosts

	echo -n " * Service "
	service hostname start 2>/dev/null || echo "hostname already started"

	if [ -f "$HOME/.Xauthority" ] ; then
		su "$SUDO_USER" -c "xauth -n list | grep -v $CURRENT_HOSTNAME | cut -f1 -d\ | xargs -i xauth remove {}"
		su "$SUDO_USER" -c "xauth add $(xauth -n list | tail -1 | sed 's/^.*\//'$NEW_HOSTNAME'\//g')"
		echo " * X authority file updated"
	fi
	
	avahi-daemon --kill

	echo " * Hostname changed to $NEW_HOSTNAME"
}


# Check Tor configs
check_configs() {

	grep -q -x 'RUN_DAEMON="yes"' /etc/default/tor
	if [ $? -ne 0 ]; then
		echo "\n[!] Please add the following to your '/etc/default/tor' and restart the service:\n"
		echo ' RUN_DAEMON="yes"\n'
		exit 1
	fi

	grep -q -x 'VirtualAddrNetwork 10.192.0.0/10' /etc/tor/torrc
	VAR1=$?

	grep -q -x 'TransPort 127.0.0.1:9040 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr' /etc/tor/torrc
	VAR2=$?

	grep -q -x 'SocksPort 127.0.0.1:9050 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr' /etc/tor/torrc
	VAR3=$?

	grep -q -x 'DNSPort 127.0.0.1:53' /etc/tor/torrc
	VAR4=$?

	grep -q -x 'AutomapHostsOnResolve 1' /etc/tor/torrc
	VAR5=$?

	if [ $VAR1 -ne 0 ] || [ $VAR2 -ne 0 ] || [ $VAR3 -ne 0 ] || [ $VAR4 -ne 0 ] || [ $VAR5 -ne 0 ] ; then
		echo "\n[!] Please add the following to your '/etc/tor/torrc' and restart service:\n"
		echo ' VirtualAddrNetwork 10.192.0.0/10'
		echo ' TransPort 127.0.0.1:9040 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr'
		echo ' SocksPort 127.0.0.1:9050 IsolateClientAddr IsolateSOCKSAuth IsolateClientProtocol IsolateDestPort IsolateDestAddr'
		echo ' DNSPort 127.0.0.1:53'
		echo ' AutomapHostsOnResolve 1\n'
		exit 1
	fi
}

iptables_flush() {
	iptables -F
	iptables -t nat -F
	echo " * Deleted all iptables rules"
}

redirect_to_tor() {
	
	echo

	if [ ! -e /var/run/tor/tor.pid ]; then
		echo "\n[!] Tor is not running! Quitting...\n"
		exit 1
	fi

	if ! [ -f /etc/network/iptables.rules ]; then
		iptables-save > /etc/network/iptables.rules
		echo " * Saved iptables rules"
	fi

	iptables_flush

	echo -n " * Service "
	service resolvconf stop 2>/dev/null || echo "resolvconf already stopped"

	echo 'nameserver 127.0.0.1\nnameserver 195.54.164.39' > /etc/resolv.conf
	echo -e " * Modified resolv.conf to use Tor & CCC(Chaos Computer Club)"
	# disable ipv6
	echo -e " Disabling IPv6 for security reasons\n"
	/sbin/sysctl -w net.ipv6.conf.all.disable_ipv6=1
	/sbin/sysctl -w net.ipv6.conf.default.disable_ipv6=1
    iptables -t nat -A INPUT -p udp --sport 53 -j ACCEPT
    iptables -t nat -A INPUT -i tun0 -j ACCEPT
    iptables -t nat -A INPUT -s 192.168.2.72 -j ACCEPT
    iptables -t nat -A OUTPUT -o tun0 -j ACCEPT
    iptables -t nat -A OUTPUT -d 192.168.2.72 -j ACCEPT
	iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
	iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 53

	for NET in $NON_TOR 127.0.0.0/9 127.128.0.0/10; do
		iptables -t nat -A OUTPUT -d "$NET" -j RETURN
	done

	iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $TRANS_PORT
	/usr/sbin/iptables -t nat -A OUTPUT -p udp -j REDIRECT --to-ports $TRANS_PORT
	/usr/sbin/iptables -t nat -A OUTPUT -p icmp -j REDIRECT --to-ports $TRANS_PORT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	for NET in $NON_TOR 127.0.0.0/8; do
		iptables -A OUTPUT -d "$NET" -j ACCEPT
	done

	iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
	iptables -A OUTPUT -j REJECT
}

# BleachBit cleaners deletes unnecessary files to preserve privacy
do_bleachbit() {
	if [ "$OVERWRITE" = "true" ] ; then
		echo -n "\n * Deleting and overwriting unnecessary files... "
		bleachbit -o -c $BLEACHBIT_CLEANERS >/dev/null
	else
		echo -n "\n * Deleting unnecessary files... "
		bleachbit -c $BLEACHBIT_CLEANERS >/dev/null
	fi

	echo "Done!"
}

do_start() {
	check_configs
	check_root

	service tor start
	sleep 3
	echo "\n[i] Starting OpSec Tunnel\n"

	echo -n " * Service "
	service NetworkManager stop 2>/dev/null || echo " NetworkManager already stopped"

	kill_process
	
	if ask "Do you want to change the local hostname?" Y; then
		read -p "Type it or press Enter for a random one > " CHOICE

		if [ "$CHOICE" = "" ]; then
			change_hostname
		else
			change_hostname "$CHOICE"
		fi
	fi

	if ask "Do you want to transparently routing traffic through Tor?" Y; then
		redirect_to_tor
	else
		echo
	fi

	echo -n " * Service "
	service NetworkManager start 2>/dev/null || echo "NetworkManager already started"
	service tor restart
	echo
}

do_stop() {

	check_root

	echo "\n[i] Stopping OpSec Tunnel\n"

	echo -n " * Service "
	
	service NetworkManager stop 2>/dev/null || echo " NetworkManager already stopped"

	iptables_flush

	if [ -f /etc/network/iptables.rules ]; then
		iptables-restore < /etc/network/iptables.rules
		rm /etc/network/iptables.rules
		echo " * Restored iptables rules"
	fi
    /sbin/sysctl -w net.ipv6.conf.all.disable_ipv6=0
	/sbin/sysctl -w net.ipv6.conf.default.disable_ipv6=0

	echo -n " * Service "
	service resolvconf start 2>/dev/null || echo "resolvconf already started"

	kill_process
	
	if ask "Do you want to change the local hostname?" Y; then
		read -p "Type it or press Enter to restore default [$REAL_HOSTNAME] > " CHOICE

		if [ "$CHOICE" = "" ]; then
			change_hostname $REAL_HOSTNAME
		else
			change_hostname "$CHOICE"
		fi
	else
		echo
	fi
	
	echo -n " * Service "
	service NetworkManager start 2>/dev/null || echo "NetworkManager already started"
	service tor restart

	if [ "$DISPLAY" ]; then
		if ask "Delete unnecessary files to preserve your privacy?" Y; then
			do_bleachbit
		fi
	fi

	echo
}

do_status() {

	echo "\n[i] anonymous status\n"

	ifconfig -a | grep "encap:Ethernet" | awk '{print " * " $1, $5}'

	CURRENT_HOSTNAME=$(hostname)
	echo " * Hostname $CURRENT_HOSTNAME"
	
	HTML=$(curl -s https://check.torproject.org/?lang=en_US)
	IP=$(echo "$HTML" | egrep -m1 -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

	echo "$HTML" | grep -q "Congratulations. This browser is configured to use Tor."

	if [ $? -ne 0 ]; then
		echo " * IP $IP"
		echo " * Tor OFF\n"
		exit 3
	else
		echo " * IP $IP"
		echo " * Tor ON\n"
	fi
}
notify() {
	if [ -e /usr/bin/notify-send ]; then
		/usr/bin/notify-send "OpSec Tunnel" "$1"
	fi
}

export notify
change() {
	ipcheck=$(wget -qO- www.icanhazip.com)
	service tor reload
	sleep 4
	echo "Tor IP & ExitNode Changed!\n"
	notify "New TOR IP:\n$ipcheck"
	sleep 1
}
wipe() {
	echo " now wiping cache, RAM, & swap-space"
	sync; echo 3 > /proc/sys/vm/drop_caches
	swapoff -a && swapon -a
	notify "Cache, RAM & swap-space cleaned!"
}


case "$1" in
	start)
		do_start
	;;
	stop)
		do_stop
	;;
	status)
		do_status
	;;
	change)
		change
	;;
	wipe)
		wipe
	;;
	*)
		echo "Usage: $0 {start|stop|status|change|wipe}" >&2
		exit 3
	;;
esac

exit 0
