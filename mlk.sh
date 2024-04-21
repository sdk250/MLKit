# Powered by sdk250

home_path="${0%/*}/Tools"
PREF=100

# thread_socket 连接的IP(百度系)
SERVER_ADDR="110.242.70.69"

# Allow IP
ALLOW_IP="127.0.0.0/8 \
	10.0.0.0/8 \
	172.16.0.0/12 \
	169.254.0.0/16 \
	224.0.0.0/4 \
	192.168/16 \
	${SERVER_ADDR}/32"

# Only for Android operation system
PACKAGES="/data/system/packages.list"

# The package name of application you need allow
ALLOW_PACKAGES=""

# 同上，不过是针对放行UDP
ALLOW_UDP_PACKAGES=""

# 需要放行的网卡，添加 wlan+ 进入可以放行Wifi
ALLOW_LOOKUP="tun+ lo"

# Be care for using
ALLOW_UID="0"

ALLOW_PORT=20822
TCP_PORT=20802
MARK=10086
TUNDEV="tunDev"
TABLE=101
TUN_ADDR="172.24.0.7/30"

v2ray_open() {
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_dynaddr

	echo -e "# This file is automatical" \
	"genrated by \`mlk\`\n# DO NOT edit it\n" > ${home_path}/.uid

	echo -n "uid=" >> ${home_path}/.uid
	for PACKAGE in ${ALLOW_PACKAGES}
	do
		uid=$(awk "/${PACKAGE}/{print \$2}" ${PACKAGES})
		if [ ! -z ${uid} ]
		then
			echo -n "${uid} " >> ${home_path}/.uid
		fi
	done
	echo -e -n "\nudp_uid=" >> ${home_path}/.uid
	for PACKAGE in ${ALLOW_UDP_PACKAGES}
	do
		uid=$(awk "/${PACKAGE}/{print \$2}" ${PACKAGES})
		if [ ! -z ${uid} ]
		then
			echo -n "${uid} " >> ${home_path}/.uid
		fi
	done

	if [ -c /dev/tun ]
	then
		[ -f /dev/net/tun ] || ( mkdir -p /dev/net \
			&& ln -sf /dev/tun /dev/net/tun )
	else
		[ -c /dev/net/tun ] || ( mkdir -p /dev/net \
			&& mknod /dev/net/tun c 10 200 )
	fi

	iptables -t filter -I FORWARD 1 \
		-w 5 \
		-i tun+ \
		-j ACCEPT
	iptables -t filter -I FORWARD 1 \
		-w 5 \
		-o tun+ \
		-j ACCEPT
	# Allow DHCP service
	iptables -t mangle -I OUTPUT 1 \
		-w 5 \
		-p udp \
		--dport 67:68 \
		-j ACCEPT
	iptables -t mangle -I PREROUTING 1 \
		-w 5 \
		-i tun+ \
		-j ACCEPT
	iptables -t mangle -I OUTPUT 1 \
		-w 5 \
		-m owner \
		--uid ${ALLOW_UID} \
		-j ACCEPT
	# Allow DNS query service
	# iptables -t mangle -I OUTPUT 1 \
		# -w 5 \
		# -p udp \
		# --dport 53 \
		# -j ACCEPT
	for IP in ${ALLOW_IP}
	do
		iptables -t mangle -I PREROUTING 1 \
			-w 5 \
			-d ${IP} \
			-j ACCEPT
		iptables -t mangle -I OUTPUT 1 \
			-w 5 \
			-d ${IP} \
			-j ACCEPT
	done
	for LOOKUP in ${ALLOW_LOOKUP}
	do
		# Allow lookup
		iptables -t mangle -I OUTPUT 1 \
			-w 5 \
			-o ${LOOKUP} \
			-j ACCEPT
	done

	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t mangle -A OUTPUT \
			-w 5 \
			-m owner \
			--uid ${UID} \
			-j ACCEPT
	done
	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^udp_uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t mangle -A OUTPUT \
			-w 5 \
			-p udp \
			-m owner \
			--uid ${UID} \
			-j ACCEPT
	done

	# iptables -t mangle -A OUTPUT -w 5 \
		# -m owner ! --uid 0-99999 -j DROP # Deny network for kernel
	iptables -t mangle -A PREROUTING \
		-w 5 \
		-p udp \
		-j ACCEPT
	iptables -t mangle -A OUTPUT \
		-w 5 \
		-j MARK \
		--set-xmark ${MARK}
	iptables -t mangle -A PREROUTING \
		-w 5 \
		-j MARK \
		--set-xmark ${MARK}

	${home_path}/thread_socket \
		-p ${TCP_PORT} \
		-u ${ALLOW_UID} \
		-r ${SERVER_ADDR} \
		-d &> ${home_path}/sock.log
	nohup \
		${home_path}/v2ray run \
		-config ${home_path}/_v2.json \
		-format jsonv5 \
		&> ${home_path}/v2.log &
	sleep 2
	ip link set up dev ${TUNDEV} qlen 1000
	ip address add ${TUN_ADDR} dev ${TUNDEV}
	ip rule add fwmark ${MARK} lookup ${TABLE} pref ${PREF}
	ip route add default via ${TUN_ADDR%/*} dev ${TUNDEV} table ${TABLE}
	ip -6 rule add unreachable pref ${PREF} # Deny IPV6

	mv ${0%/*}/disabled ${0%/*}/enabled && echo "v2ray" > ${0%/*}/enabled
	echo -e "\x1b[92mV2ray Done.\x1b[0m"
	exit 0
}

v2ray_close() {
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 0 > /proc/sys/net/ipv4/ip_dynaddr

	iptables -t filter -D FORWARD \
		-w 5 \
		-i tun+ \
		-j ACCEPT
	iptables -t filter -D FORWARD \
		-w 5 \
		-o tun+ \
		-j ACCEPT
	# Allow DHCP service
	iptables -t mangle -D OUTPUT \
		-w 5 \
		-p udp \
		--dport 67:68 \
		-j ACCEPT
	iptables -t mangle -D PREROUTING \
		-w 5 \
		-i tun+ \
		-j ACCEPT
	iptables -t mangle -D OUTPUT \
		-w 5 \
		-m owner \
		--uid ${ALLOW_UID} \
		-j ACCEPT
	# Allow DNS query service
	# iptables -t mangle -D OUTPUT \
		# -w 5 \
		# -p udp \
		# --dport 53 \
		# -j ACCEPT
	for IP in ${ALLOW_IP}
	do
		iptables -t mangle -D PREROUTING \
			-w 5 \
			-d ${IP} \
			-j ACCEPT
		iptables -t mangle -D OUTPUT \
			-w 5 \
			-d ${IP} \
			-j ACCEPT
	done
	for LOOKUP in ${ALLOW_LOOKUP}
	do
		# Allow lookup
		iptables -t mangle -D OUTPUT \
			-w 5 \
			-o ${LOOKUP} \
			-j ACCEPT
	done

	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t mangle -D OUTPUT \
			-w 5 \
			-m owner \
			--uid ${UID} \
			-j ACCEPT
	done
	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^udp_uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t mangle -D OUTPUT \
			-w 5 \
			-p udp \
			-m owner \
			--uid ${UID} \
			-j ACCEPT
	done

	# iptables -t mangle -D OUTPUT -w 5 \
		# -m owner ! --uid 0-99999 -j DROP # Deny network for kernel
	iptables -t mangle -D PREROUTING \
		-w 5 \
		-p udp \
		-j ACCEPT
	iptables -t mangle -D OUTPUT \
		-w 5 \
		-j MARK \
		--set-xmark ${MARK}
	iptables -t mangle -D PREROUTING \
		-w 5 \
		-j MARK \
		--set-xmark ${MARK}

	ip rule del pref ${PREF}
	ip route del default dev ${TUNDEV} table ${TABLE}
	ip -6 rule del pref ${PREF} # Allow IPV6
	ip link set down dev ${TUNDEV}
	ip address del ${TUN_ADDR} dev ${TUNDEV}
	killall -9 v2ray \
		thread_socket

	rm -f ${home_path}/.uid
	mv ${0%/*}/enabled ${0%/*}/disabled
}

tiny_open() {
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_dynaddr

	echo -e "# This file is automatical" \
	"genrated by \`mlk\`\n# DO NOT edit it\n" > ${home_path}/.uid

	echo -n "uid=" >> ${home_path}/.uid
	for PACKAGE in ${ALLOW_PACKAGES}
	do
		uid=$(awk "/${PACKAGE}/{print \$2}" ${PACKAGES})
		if [ ! -z ${uid} ]
		then
			echo -n "${uid} " >> ${home_path}/.uid
		fi
	done
	echo -e -n "\nudp_uid=" >> ${home_path}/.uid
	for PACKAGE in ${ALLOW_UDP_PACKAGES}
	do
		uid=$(awk "/${PACKAGE}/{print \$2}" ${PACKAGES})
		if [ ! -z ${uid} ]
		then
			echo -n "${uid} " >> ${home_path}/.uid
		fi
	done

	if [ -c /dev/tun ]
	then
		[ -f /dev/net/tun ] || ( mkdir -p /dev/net \
			&& ln -sf /dev/tun /dev/net/tun )
	else
		[ -c /dev/net/tun ] || ( mkdir -p /dev/net \
			&& mknod /dev/net/tun c 10 200 )
	fi

	${home_path}/thread_socket \
		-p ${TCP_PORT} \
		-u ${ALLOW_UID} \
		-r ${SERVER_ADDR} \
		-d &> ${home_path}/sock.log

	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t nat -A OUTPUT -w 5 -m owner \
			--uid ${UID} -j ACCEPT
		iptables -t mangle -A OUTPUT -w 5 -m owner \
			--uid ${UID} -j ACCEPT
	done
	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^udp_uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t nat -A OUTPUT -w 5 -m owner \
			--uid ${UID} -p udp -j ACCEPT
		iptables -t mangle -A OUTPUT -w 5 -m owner \
			--uid ${UID} -p udp -j ACCEPT
	done
	iptables -t nat -A OUTPUT -w 5 -p udp \
		--dport 67:68 -j ACCEPT
	iptables -t mangle -A OUTPUT -w 5 -p udp \
		--dport 67:68 -j ACCEPT # Allow DHCP service

	for IP in ${ALLOW_IP}
	do
		iptables -t nat -I OUTPUT 1 -w 5 -d ${IP} -j ACCEPT
		iptables -t mangle -I OUTPUT 1 -w 5 -d ${IP} -j ACCEPT
		iptables -t nat -I PREROUTING 1 -w 5 -d ${IP} -j ACCEPT
		iptables -t mangle -I PREROUTING 1 -w 5 -d ${IP} -j ACCEPT
	done
	for LOOKUP in ${ALLOW_LOOKUP}
	do
		iptables -t nat -I OUTPUT 1 -w 5 -o ${LOOKUP} -j ACCEPT
		iptables -t mangle -I OUTPUT 1 -w 5 \
			-o ${LOOKUP} -j ACCEPT # Allow lookup
	done
	iptables -t nat -I OUTPUT 1 -w 5 -m owner --uid ${ALLOW_UID} -j ACCEPT
	iptables -t mangle -I OUTPUT 1 -w 5 -m owner --uid ${ALLOW_UID} -j ACCEPT

	# Begin proxy TCP
	# iptables -t mangle -A OUTPUT -w 5 -m owner ! --uid 0-99999 -j DROP
	iptables -t nat -A OUTPUT -w 5 -p tcp \
		-j REDIRECT --to ${TCP_PORT}
	# iptables -t nat -A OUTPUT -w 5 -p udp \
		# --dport 53 -j REDIRECT --to 65053
	# Allow DNS network
	iptables -t nat -A OUTPUT -w 5 -p udp --dport 53 -j ACCEPT
	iptables -t mangle -P OUTPUT DROP -w 5
	iptables -t mangle -I OUTPUT -w 5 -p tcp \
		-m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	iptables -t mangle -I OUTPUT -w 5 -p udp \
		--dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	# End proxy TCP

	# Begin proxy forward
	iptables -t mangle -P FORWARD DROP -w 5
	ip6tables -t mangle -P FORWARD DROP -w 5
	iptables -t nat -A PREROUTING -w 5 -s 192.168/16 \
		-p tcp -j REDIRECT --to ${TCP_PORT}
	# iptables -t nat -A PREROUTING -w 5 -s 192.168/16 \
		# -p udp --dport 53 -j REDIRECT --to 65053
	# Allow forward DNS network
	iptables -t mangle -A FORWARD -w 5 -p udp --dport 53 -j ACCEPT
	# End proxy forward

	mv ${0%/*}/disabled ${0%/*}/enabled && echo "thread_socket" > ${0%/*}/enabled
	echo -e "\x1b[92mTiny Done.\x1b[0m"
	exit 0
}

tiny_close() {
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 0 > /proc/sys/net/ipv4/ip_dynaddr

	killall -9 thread_socket

	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t nat -D OUTPUT -w 5 -m owner \
			--uid ${UID} -j ACCEPT
		iptables -t mangle -D OUTPUT -w 5 -m owner \
			--uid ${UID} -j ACCEPT
	done
	for UID in $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E -o '^udp_uid=.+' | grep -E -o '[0-9]+ ?'
	)
	do
		iptables -t nat -D OUTPUT -w 5 -m owner \
			--uid ${UID} -p udp -j ACCEPT
		iptables -t mangle -D OUTPUT -w 5 -m owner \
			--uid ${UID} -p udp -j ACCEPT
	done
	iptables -t nat -D OUTPUT -w 5 -p udp \
		--dport 67:68 -j ACCEPT
	iptables -t mangle -D OUTPUT -w 5 -p udp \
		--dport 67:68 -j ACCEPT # Allow DHCP service

	for IP in ${ALLOW_IP}
	do
		iptables -t nat -D OUTPUT -w 5 -d ${IP} -j ACCEPT
		iptables -t mangle -D OUTPUT -w 5 -d ${IP} -j ACCEPT
		iptables -t nat -D PREROUTING -w 5 -d ${IP} -j ACCEPT
		iptables -t mangle -D PREROUTING -w 5 -d ${IP} -j ACCEPT
	done
	for LOOKUP in ${ALLOW_LOOKUP}
	do
		iptables -t nat -D OUTPUT -w 5 -o ${LOOKUP} -j ACCEPT
		iptables -t mangle -D OUTPUT -w 5 \
			-o ${LOOKUP} -j ACCEPT # Allow lookup
	done
	iptables -t nat -D OUTPUT -w 5 -m owner --uid ${ALLOW_UID} -j ACCEPT
	iptables -t mangle -D OUTPUT -w 5 -m owner --uid ${ALLOW_UID} -j ACCEPT

	# Begin proxy TCP
	# iptables -t mangle -D OUTPUT -w 5 -m owner ! --uid 0-99999 -j DROP
	iptables -t nat -D OUTPUT -w 5 -p tcp \
		-j REDIRECT --to ${TCP_PORT}
	# iptables -t nat -D OUTPUT -w 5 -p udp \
		# --dport 53 -j REDIRECT --to 65053
	# Allow DNS network
	iptables -t nat -D OUTPUT -p udp --dport 53 -j ACCEPT
	iptables -t mangle -P OUTPUT ACCEPT -w 5
	iptables -t mangle -D OUTPUT -w 5 -p tcp \
		-m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	iptables -t mangle -D OUTPUT -w 5 -p udp \
		--dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	# End proxy TCP

	# Begin proxy forward
	iptables -t mangle -P FORWARD ACCEPT -w 5
	ip6tables -t mangle -P FORWARD ACCEPT -w 5
	iptables -t nat -D PREROUTING -w 5 -s 192.168/16 \
		-p tcp -j REDIRECT --to ${TCP_PORT}
	# iptables -t nat -D PREROUTING -w 5 -s 192.168/16 \
		# -p udp --dport 53 -j REDIRECT --to 65053
	# Allow forward DNS network
	iptables -t mangle -D FORWARD -w 5 -p udp --dport 53 -j ACCEPT
	# End proxy forward

	rm -f ${home_path}/.uid
	mv ${0%/*}/enabled ${0%/*}/disabled
}

if [ -f ${0%/*}/disabled ]
then
	if [ ${#} -eq 1 ]
	then
		if [ ${1} == "t" ]
		then
			tiny_open
		elif [ ${1} == "v" ]
		then
			v2ray_open
		else
			echo "Undefined core."
			exit -1
		fi
	else
		echo "Need a parameter of core."
		exit -3
	fi
elif [ -f ${0%/*}/enabled ]
then
	if [ ${#} -eq 1 ]
	then
		status=$(cat ${0%/*}/enabled)
		if [ ${1} == "t" ]
		then
			if [ "v2ray" == ${status} ]
			then
				v2ray_close
				tiny_open
			elif [ "thread_socket" == ${status} ]
			then
				tiny_close
				exit 0
			else
				echo "Undefined error."
				exit -2
			fi
		elif [ ${1} == "v" ]
		then
			if [ "thread_socket" == ${status} ]
			then
				tiny_close
				v2ray_open
			elif [ "v2ray" == ${status} ]
			then
				v2ray_close
				exit 0
			else
				echo "Undefined error."
				exit -2
			fi
		else
			echo "Selecting core is invalid."
			exit -3
		fi
	else
		echo "Need a parameter of core."
		exit -3
	fi
else
	echo "Undefined error."
	exit 1
fi
exit 127
