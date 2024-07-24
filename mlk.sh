# Powered by sdk250

home_path="${0%/*}/Tools"

# thread_socket 连接的IP(百度系)
SERVER_ADDR="157.0.148.53"

# Allow IP
ALLOW_IP="127.0.0.0/8 \
	10.0.0.0/8 \
	172.16.0.0/12 \
	169.254.0.0/16 \
	224.0.0.0/4 \
	192.168/16 \
	${SERVER_ADDR}/32"

# 仅适用于Android系统
PACKAGES="/data/system/packages.list"

# 在 Android 系统中的需要放行的应用的包名
ALLOW_PACKAGES="com.android.bankabc \
	com.nasoft.socmark \
	com.v2ray.ang \
	com.tmri.app.main"

# 同上，不过是针对放行UDP
ALLOW_UDP_PACKAGES="com.tencent.tmgp.pubgmhd \
	com.tencent.tmgp.sgame \
	com.miHoYo.Yuanshen"

# 适用于 Linux，需要放行的UID
ALLOW_ALL_UID=''

# UDP 放行
ALLOW_UDP_UID=''

# 放行本机DNS
ALLOW_LOCAL_DNS=1

# 放行热点DNS
ALLOW_REMOTE_DNS=1

# 放行本机UDP
ALLOW_LOCAL_UDP=0

# 放行本机TCP
ALLOW_LOCAL_TCP=0

# 放行热点UDP
ALLOW_REMOTE_UDP=0

# 放行热点TCP
ALLOW_REMOTE_TCP=0

# 需要放行的网卡，添加 wlan+ 进入可以放行Wifi
ALLOW_LOOKUP='tun+ lo'

# Be care for using
ALLOW_UID=0

ALLOW_PORT=20822
TCP_PORT=20802
MARK=10086
TUNDEV='tunDev'
TABLE=101
PREF=100
TUN_ADDR='172.24.0.1/30'
WAIT_TIME=3

generate_uid()
{
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
	echo -n "${ALLOW_ALL_UID} " >> ${home_path}/.uid
	echo -e -n "\nudp_uid=" >> ${home_path}/.uid
	for PACKAGE in ${ALLOW_UDP_PACKAGES}
	do
		uid=$(awk "/${PACKAGE}/{print \$2}" ${PACKAGES})
		if [ ! -z ${uid} ]
		then
			echo -n "${uid} " >> ${home_path}/.uid
		fi
	done
	echo -n "${ALLOW_UDP_UID} " >> ${home_path}/.uid

	# Saving configuration
	echo -e -n '\n' >> ${home_path}/.uid
	echo "SERVER_ADDR=${SERVER_ADDR}" >> ${home_path}/.uid
	echo "ALLOW_IP=${ALLOW_IP}" >> ${home_path}/.uid
	echo "PACKAGES=${PACKAGES}" >> ${home_path}/.uid
	echo "ALLOW_PACKAGES=${ALLOW_PACKAGES}" >> ${home_path}/.uid
	echo "ALLOW_UDP_PACKAGES=${ALLOW_UDP_PACKAGES}" >> ${home_path}/.uid
	echo "ALLOW_ALL_UID=${ALLOW_ALL_UID}" >> ${home_path}/.uid
	echo "ALLOW_UDP_UID=${ALLOW_UDP_UID}" >> ${home_path}/.uid
	echo "ALLOW_LOCAL_DNS=${ALLOW_LOCAL_DNS}" >> ${home_path}/.uid
	echo "ALLOW_REMOTE_DNS=${ALLOW_REMOTE_DNS}" >> ${home_path}/.uid
	echo "ALLOW_LOCAL_UDP=${ALLOW_LOCAL_UDP}" >> ${home_path}/.uid
	echo "ALLOW_LOCAL_TCP=${ALLOW_LOCAL_TCP}" >> ${home_path}/.uid
	echo "ALLOW_REMOTE_UDP=${ALLOW_REMOTE_UDP}" >> ${home_path}/.uid
	echo "ALLOW_REMOTE_TCP=${ALLOW_REMOTE_TCP}" >> ${home_path}/.uid
	echo "ALLOW_LOOKUP=${ALLOW_LOOKUP}" >> ${home_path}/.uid
	echo "ALLOW_UID=${ALLOW_UID}" >> ${home_path}/.uid
	echo "ALLOW_PORT=${ALLOW_PORT}" >> ${home_path}/.uid
	echo "TCP_PORT=${TCP_PORT}" >> ${home_path}/.uid
	echo "MARK=${MARK}" >> ${home_path}/.uid
	echo "TUNDEV=${TUNDEV}" >> ${home_path}/.uid
	echo "TABLE=${TABLE}" >> ${home_path}/.uid
	echo "PREF=${PREF}" >> ${home_path}/.uid
	echo "TUN_ADDR=${TUN_ADDR}" >> ${home_path}/.uid
	echo "WAIT_TIME=${WAIT_TIME}" >> ${home_path}/.uid
}

create_tun()
{
	if [ -c /dev/tun ]
	then
		[ -f /dev/net/tun ] || ( mkdir -p /dev/net \
			&& ln -sf /dev/tun /dev/net/tun )
	else
		[ -c /dev/net/tun ] || ( mkdir -p /dev/net \
			&& mknod /dev/net/tun c 10 200 \
			&& chmod 600 /dev/net/tun )
	fi
}

find_configuration()
{
	echo $(grep -E '^[^#]' ${home_path}/.uid | \
		grep -E "^${1}=" | awk -F= '{print $2}' \
	)
}

load_configuration()
{
	SERVER_ADDR=$(find_configuration SERVER_ADDR)
	ALLOW_IP=$(find_configuration ALLOW_IP)
	PACKAGES=$(find_configuration PACKAGES)
	ALLOW_PACKAGES=$(find_configuration ALLOW_PACKAGES)
	ALLOW_UDP_PACKAGES=$(find_configuration ALLOW_UDP_PACKAGES)
	ALLOW_ALL_UID=$(find_configuration ALLOW_ALL_UID)
	ALLOW_UDP_UID=$(find_configuration ALLOW_UDP_UID)
	ALLOW_LOCAL_DNS=$(find_configuration ALLOW_LOCAL_DNS)
	ALLOW_REMOTE_DNS=$(find_configuration ALLOW_REMOTE_DNS)
	ALLOW_LOCAL_UDP=$(find_configuration ALLOW_LOCAL_UDP)
	ALLOW_LOCAL_TCP=$(find_configuration ALLOW_LOCAL_TCP)
	ALLOW_REMOTE_UDP=$(find_configuration ALLOW_REMOTE_UDP)
	ALLOW_REMOTE_TCP=$(find_configuration ALLOW_REMOTE_TCP)
	ALLOW_LOOKUP=$(find_configuration ALLOW_LOOKUP)
	ALLOW_UID=$(find_configuration ALLOW_UID)
	ALLOW_PORT=$(find_configuration ALLOW_PORT)
	TCP_PORT=$(find_configuration TCP_PORT)
	MARK=$(find_configuration MARK)
	TUNDEV=$(find_configuration TUNDEV)
	TABLE=$(find_configuration TABLE)
	PREF=$(find_configuration PREF)
	TUN_ADDR=$(find_configuration TUN_ADDR)
	WAIT_TIME=$(find_configuration WAIT_TIME)
}

allow_app_network()
{
	for UID in $(find_configuration uid)
	do
		iptables -t ${1} ${2} OUTPUT ${3} \
			-w ${WAIT_TIME} \
			-m owner \
			--uid ${UID} \
			-j ACCEPT
	done
	for UID in $(find_configuration udp_uid)
	do
		iptables -t ${1} ${2} OUTPUT ${3} \
			-w ${WAIT_TIME} \
			-p udp \
			-m owner \
			--uid ${UID} \
			-j ACCEPT
	done
}

allow_core()
{
	# Allow DHCP service
	iptables -t ${1} ${2} OUTPUT ${3} \
		-w ${WAIT_TIME} \
		-p udp \
		--dport 67:68 \
		-j ACCEPT

	for IP in ${ALLOW_IP}
	do
		# Allow IP range
		iptables -t ${1} ${2} PREROUTING ${3} \
			-w ${WAIT_TIME} \
			-d ${IP} \
			-j ACCEPT
		iptables -t ${1} ${2} OUTPUT ${3} \
			-w ${WAIT_TIME} \
			-d ${IP} \
			-j ACCEPT
	done
	for LOOKUP in ${ALLOW_LOOKUP}
	do
		# Allow lookup
		iptables -t ${1} ${2} OUTPUT ${3} \
			-w ${WAIT_TIME} \
			-o ${LOOKUP} \
			-j ACCEPT
	done
}

v2ray_rule_1()
{
	iptables -t filter ${1} FORWARD ${2} \
		-w ${WAIT_TIME} \
		-i tun+ \
		-j ACCEPT
	iptables -t filter ${1} FORWARD ${2} \
		-w ${WAIT_TIME} \
		-o tun+ \
		-j ACCEPT
	iptables -t mangle ${1} PREROUTING ${2} \
		-w ${WAIT_TIME} \
		-i tun+ \
		-j ACCEPT
	iptables -t mangle ${1} OUTPUT ${2} \
		-w ${WAIT_TIME} \
		-m owner \
		--uid ${ALLOW_UID} \
		-j ACCEPT

	# Allow DNS query service
	[ ${ALLOW_LOCAL_DNS} == 1 ] && iptables -t mangle ${1} OUTPUT ${2} \
		-w ${WAIT_TIME} \
		-p udp \
		--dport 53 \
		-j ACCEPT
	[ ${ALLOW_REMOTE_DNS} == 1 ] && iptables -t mangle ${1} PREROUTING ${2} \
		-w ${WAIT_TIME} \
		-p udp \
		--dport 53 \
		-j ACCEPT

	allow_core mangle ${1} ${2}
}

v2ray_rule_2()
{
	allow_app_network mangle ${1}

	[ ${ALLOW_REMOTE_UDP} == 1 ] && iptables -t mangle ${1} PREROUTING \
		-w ${WAIT_TIME} \
		-p udp \
		-j ACCEPT
	[ ${ALLOW_REMOTE_TCP} == 1 ] && iptables -t mangle ${1} PREROUTING \
		-w ${WAIT_TIME} \
		-p tcp \
		-j ACCEPT
	[ ${ALLOW_LOCAL_UDP} == 1 ] && iptables -t mangle ${1} OUTPUT \
		-w ${WAIT_TIME} \
		-p udp \
		-j ACCEPT
	[ ${ALLOW_LOCAL_TCP} == 1 ] && iptables -t mangle ${1} OUTPUT \
		-w ${WAIT_TIME} \
		-p tcp \
		-j ACCEPT
}

tiny_rule_1()
{
	allow_core nat ${1} ${2}
	allow_core mangle ${1} ${2}

	iptables -t nat ${1} OUTPUT ${2} \
		-w ${WAIT_TIME} \
		-m owner \
		--uid ${ALLOW_UID} \
		-j ACCEPT
	iptables -t mangle ${1} OUTPUT ${2} \
		-w ${WAIT_TIME} \
		-m owner \
		--uid ${ALLOW_UID} \
		-j ACCEPT
	iptables -t mangle ${1} OUTPUT ${2} \
		-w ${WAIT_TIME} \
		-p tcp \
		-m state \
		--state NEW,ESTABLISHED,RELATED \
		-j ACCEPT
	iptables -t mangle ${1} OUTPUT ${2} \
		-w ${WAIT_TIME} \
		-p udp \
		--dport 53 \
		-m state \
		--state NEW,ESTABLISHED,RELATED \
		-j ACCEPT
}

tiny_rule_2()
{
	allow_app_network nat ${1}
	allow_app_network mangle ${1}

	# Begin proxy TCP
	# iptables -t mangle ${1} OUTPUT -w ${WAIT_TIME} -m owner ! --uid 0-99999 -j DROP
	iptables -t nat ${1} OUTPUT \
		-w ${WAIT_TIME} \
		-p tcp \
		-j REDIRECT \
		--to ${TCP_PORT}
	# iptables -t nat ${1} OUTPUT -w ${WAIT_TIME} -p udp \
		# --dport 53 -j REDIRECT --to 65053

	# Allow DNS network
	iptables -t nat ${1} OUTPUT \
		-w ${WAIT_TIME} \
		-p udp \
		--dport 53 \
		-j ACCEPT

	iptables -t mangle -P OUTPUT ${2} -w ${WAIT_TIME}
	# End proxy TCP

	# Begin proxy forward
	iptables -t mangle -P FORWARD ${2} -w ${WAIT_TIME}
	ip6tables -t mangle -P FORWARD ${2} -w ${WAIT_TIME}
	iptables -t nat ${1} PREROUTING \
		-w ${WAIT_TIME} \
		-p tcp \
		-j REDIRECT \
		--to ${TCP_PORT}
	# iptables -t nat ${1} PREROUTING -w ${WAIT_TIME} \
		# -p udp --dport 53 -j REDIRECT --to 65053

	# Allow forward DNS network
	iptables -t mangle ${1} FORWARD \
		-w ${WAIT_TIME} \
		-p udp \
		--dport 53 \
		-j ACCEPT
	# End proxy forward
}

v2ray_open() {
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_dynaddr

	generate_uid

	create_tun

	v2ray_rule_1 -I 1

	v2ray_rule_2 -A

	# iptables -t mangle -A OUTPUT -w ${WAIT_TIME} \
		# -m owner ! --uid 0-99999 -j DROP # Deny network for kernel

	iptables -t mangle -A OUTPUT \
		-w ${WAIT_TIME} \
		-j MARK \
		--set-xmark ${MARK}
	iptables -t mangle -A PREROUTING \
		-w ${WAIT_TIME} \
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
	sleep 1
	ip address add ${TUN_ADDR} dev ${TUNDEV}
	ip link set up dev ${TUNDEV} qlen 1000
	ip rule add fwmark ${MARK} lookup ${TABLE} pref ${PREF}
	ip route add default via ${TUN_ADDR%/*} dev ${TUNDEV} table ${TABLE}
	# ip -6 rule add unreachable pref ${PREF} # Deny IPV6

	mv ${0%/*}/disabled ${0%/*}/enabled && echo "v2ray" > ${0%/*}/enabled
	echo -e "\x1b[92mV2ray Done.\x1b[0m"
	exit 0
}

v2ray_close() {
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 0 > /proc/sys/net/ipv4/ip_dynaddr

	load_configuration

	v2ray_rule_1 -D

	v2ray_rule_2 -D

	# iptables -t mangle -D OUTPUT -w ${WAIT_TIME} \
		# -m owner ! --uid 0-99999 -j DROP # Deny network for kernel

	iptables -t mangle -D OUTPUT \
		-w ${WAIT_TIME} \
		-j MARK \
		--set-xmark ${MARK}
	iptables -t mangle -D PREROUTING \
		-w ${WAIT_TIME} \
		-j MARK \
		--set-xmark ${MARK}

	ip rule del pref ${PREF}
	ip route del default dev ${TUNDEV} table ${TABLE}
	# ip -6 rule del pref ${PREF} # Allow IPV6
	ip link set down dev ${TUNDEV}
	ip address del ${TUN_ADDR} dev ${TUNDEV}
	killall v2ray \
		thread_socket

	rm -f ${home_path}/.uid
	mv ${0%/*}/enabled ${0%/*}/disabled
}

tiny_open() {
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_dynaddr

	generate_uid

	create_tun

	${home_path}/thread_socket \
		-p ${TCP_PORT} \
		-u ${ALLOW_UID} \
		-r ${SERVER_ADDR} \
		-d &> ${home_path}/sock.log

	tiny_rule_1 -I 1

	tiny_rule_2 -A DROP

	mv ${0%/*}/disabled ${0%/*}/enabled && echo "thread_socket" > ${0%/*}/enabled
	echo -e "\x1b[92mTiny Done.\x1b[0m"
	exit 0
}

tiny_close() {
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo 0 > /proc/sys/net/ipv4/ip_dynaddr

	load_configuration

	killall thread_socket

	tiny_rule_1 -D

	tiny_rule_2 -D ACCEPT

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
		elif [ 's' == ${1} ]
		then
			echo 'MLKit is stopped.'
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
		elif [ 's' == ${1} ]
		then
			echo "MLKit is running. (${status})"
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

