#!/system/bin/sh
# Powered by sdk250

home_path="${0%/*}/Tools"
PREF=100
ALLOW_IP="157.255.78.51"
LOOPADDR="192.168/16"
ALLOW_UID="" #"10297 10272"
ALLOW_UDP_UID="10357"
ALLOW="wlan+ tun+ lo"
MARK=999
TUNDEV="tun0"
TABLE=101

if [ -f "${0%/*}/disabled" ]
then
	svc data disable
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_dynaddr

	# iptables -t mangle -N TUN_OUTPUT -w 5
	# iptables -t mangle -P OUTPUT DROP -w 5
	# iptables -t mangle -P PREROUTING DROP -w 5

	[ -f "/dev/net/tun" ] || mkdir -p /dev/net && ln -sf /dev/tun /dev/net/tun
	for ilink in ${ALLOW}
	do
		iptables -t mangle -A OUTPUT -w 5 -o ${ilink} -j ACCEPT # Allow lookup
	done
	for UID in ${ALLOW_UID}
	do
		iptables -t mangle -A OUTPUT -w 5 -m owner --uid ${UID} -j ACCEPT
	done
	for UID in ${ALLOW_UDP_UID}
	do
		iptables -t mangle -A OUTPUT -w 5 -p udp -m owner --uid ${UID} -j ACCEPT
	done
	iptables -t mangle -A OUTPUT -w 5 -d ${LOOPADDR} -j ACCEPT
	iptables -t mangle -A OUTPUT -w 5 -m owner --uid 3004 -j ACCEPT
	iptables -t mangle -A OUTPUT -w 5 -p udp --dport 67:68 -j ACCEPT # Allow DHCP service
	iptables -t mangle -A OUTPUT -w 5 -m owner ! --uid 0-99999 -j DROP # Deny network for kernel
	iptables -t mangle -A OUTPUT -w 5 -j MARK --set-xmark ${MARK}
	# iptables -t mangle -A TUN_PREROUTING -w 5 -p udp -j ACCEPT # Allow PREROUTING udp network
	for IP in ${ALLOW_IP}
	do
		iptables -t mangle -A PREROUTING -w 5 -d ${IP} -j ACCEPT
	done
	iptables -t mangle -A PREROUTING -w 5 -i tun+ -j ACCEPT
	iptables -t mangle -A PREROUTING -w 5 -d ${LOOPADDR} ! -p udp -j ACCEPT
	iptables -t mangle -A PREROUTING -w 5 -d ${LOOPADDR} -p udp ! --dport 53 -j ACCEPT
	iptables -t mangle -A PREROUTING -w 5 -j MARK --set-xmark ${MARK}

	iptables -t filter -I FORWARD 1 -w 5 -i tun+ -j ACCEPT
	iptables -t filter -I FORWARD 1 -w 5 -o tun+ -j ACCEPT
	# iptables -t mangle -I PREROUTING 1 -w 5 ! -i tun+ -g TUN_PREROUTING
	# iptables -t mangle -I OUTPUT 1 -w 5 ! -o lo ! -d ${LOOPADDR} -m owner ! --gid 3004 -g TUN_OUTPUT

	${home_path}/tiny -s -c ${home_path}/tiny.conf > ${home_path}/tiny.log 2>&1
	nohup su 3004 -c "${home_path}/v2ray run -c ${home_path}/config.json" > ${home_path}/v2ray.log 2>&1 &
	nohup ${home_path}/tun2socks-linux-arm64 \
		-device ${TUNDEV} \
		-proxy socks5://127.0.0.1:10800 \
		-loglevel info > ${home_path}/tun2socks.log 2>&1 &
	sleep 1.5
	ip addr add 10.0.0.1/24 dev ${TUNDEV}
	ip link set dev ${TUNDEV} up qlen 3000
	ip rule add fwmark ${MARK} lookup ${TABLE} pref ${PREF}
	ip route add default dev ${TUNDEV} table ${TABLE}
	ip -6 rule add unreachable pref ${PREF} # Deny IPV6

	rm ${0%/*}/disabled
	touch ${0%/*}/enabled
	svc data enable
	echo "\x1b[92;mDone.\x1b[0m"
	exit 0
elif [ -f "${0%/*}/enabled" ]
then
	svc data disable
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 0 > /proc/sys/net/ipv4/ip_dynaddr

	# iptables -t mangle -P OUTPUT ACCEPT -w 5
	# iptables -t mangle -P PREROUTING ACCEPT -w 5

	for ilink in ${ALLOW}
	do
		iptables -t mangle -D OUTPUT -w 5 -o ${ilink} -j ACCEPT # Allow lookup
	done
	for UID in ${ALLOW_UID}
	do
		iptables -t mangle -D OUTPUT -w 5 -m owner --uid ${UID} -j ACCEPT
	done
	for UID in ${ALLOW_UDP_UID}
	do
		iptables -t mangle -D OUTPUT -w 5 -p udp -m owner --uid ${UID} -j ACCEPT
	done
	iptables -t mangle -D OUTPUT -w 5 -d ${LOOPADDR} -j ACCEPT
	iptables -t mangle -D OUTPUT -w 5 -m owner --uid 3004 -j ACCEPT
	iptables -t mangle -D OUTPUT -w 5 -p udp --dport 67:68 -j ACCEPT # Allow DHCP service
	iptables -t mangle -D OUTPUT -w 5 -m owner ! --uid 0-99999 -j DROP # Deny network for kernel
	iptables -t mangle -D OUTPUT -w 5 -j MARK --set-xmark ${MARK}
	# iptables -t mangle -D TUN_PREROUTING -w 5 -p udp -j ACCEPT # Allow PREROUTING udp network
	for IP in ${ALLOW_IP}
	do
		iptables -t mangle -D PREROUTING -w 5 -d ${IP} -j ACCEPT
	done
	iptables -t mangle -D PREROUTING -w 5 -i tun+ -j ACCEPT
	iptables -t mangle -D PREROUTING -w 5 -d ${LOOPADDR} ! -p udp -j ACCEPT
	iptables -t mangle -D PREROUTING -w 5 -d ${LOOPADDR} -p udp ! --dport 53 -j ACCEPT
	iptables -t mangle -D PREROUTING -w 5 -j MARK --set-xmark ${MARK}

	iptables -t filter -D FORWARD -w 5 -i tun+ -j ACCEPT
	iptables -t filter -D FORWARD -w 5 -o tun+ -j ACCEPT
	# iptables -t mangle -D PREROUTING -w 5 ! -i tun+ -g PREROUTING
	# iptables -t mangle -D OUTPUT -w 5 ! -o lo ! -d ${LOOPADDR} -m owner ! --gid 3004 -g TUN_OUTPUT

	# iptables -t mangle -X TUN_OUTPUT -w 5
	# iptables -t mangle -X TUN_PREROUTING -w 5

	ip rule del pref ${PREF}
	ip route del default dev ${TUNDEV} table ${TABLE}
	ip -6 rule del pref ${PREF} # Allow IPV6

	killall tiny v2ray tun2socks-linux-arm64

	rm ${0%/*}/enabled
	touch ${0%/*}/disabled
	svc data enable
	exit 0
else
	echo "Undefined error."
	exit 1
fi
exit 127
