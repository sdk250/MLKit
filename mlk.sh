#!/system/bin/sh
# Powered by sdk250

home_path="${0%/*}/Tools"

# thread_socket 连接的IP(百度系)
SERVER_ADDR='110.242.70.68'

# Allow IP
ALLOW_IP="127.0.0.0/8 \
  10.0.0.0/8 \
  172.16.0.0/12 \
  169.254.0.0/16 \
  224.0.0.0/4 \
  192.168.0.0/16 \
  240.0.0.0/4 \
  255.255.255.255/32 \
  ${SERVER_ADDR}/32"

ALLOW_IPv6="fe80::/64"

ENABLE_IPv6=1

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
ALLOW_LOCAL_DNS=0

# 放行热点DNS
ALLOW_REMOTE_DNS=0

# 放行本机UDP
ALLOW_LOCAL_UDP=0

# 放行本机TCP
ALLOW_LOCAL_TCP=0

# 放行热点UDP
ALLOW_REMOTE_UDP=0

# 放行热点TCP
ALLOW_REMOTE_TCP=0

# 放行 WiFi
ALLOW_WLAN=0

# 需要放行的网卡，添加 wlan+ 进入可以放行Wifi
ALLOW_LOOKUP='tun+ lo'

# Be care for using
ALLOW_UID=0

ALLOW_PORT=20822
TCP_PORT=20802
MARK=10086
GID=10086
TUNDEV='tunDev'
TABLE=101
PREF=100
TUN_ADDR='172.24.0.1/30'
WAIT_TIME=3

echo_v()
{
  eval "local value=\$${1}"
  echo "${1}=${value}" >> ${home_path}/.uid
}

generate_uid()
{
  echo -e "# This file is automatical" \
  "genrated by \`mlk\`\n# DO NOT edit it\n" > ${home_path}/.uid

  echo -n "ALLOW_ALL_UID=" >> ${home_path}/.uid
  find_uid "${ALLOW_PACKAGES}" "${ALLOW_ALL_UID}"
  echo -n "ALLOW_UDP_UID=" >> ${home_path}/.uid
  find_uid "${ALLOW_UDP_PACKAGES}" "${ALLOW_UDP_UID}"

  # Saving configuration
  local vars
  vars=(
    SERVER_ADDR
    ALLOW_IP
    ALLOW_IPv6
    ENABLE_IPv6
    PACKAGES
    ALLOW_PACKAGES
    ALLOW_UDP_PACKAGES
    ALLOW_LOCAL_DNS
    ALLOW_REMOTE_DNS
    ALLOW_LOCAL_UDP
    ALLOW_LOCAL_TCP
    ALLOW_REMOTE_UDP
    ALLOW_REMOTE_TCP
    ALLOW_WLAN
    ALLOW_LOOKUP
    ALLOW_UID
    ALLOW_PORT
    TCP_PORT
    MARK
    TUNDEV
    TABLE
    PREF
    TUN_ADDR
    WAIT_TIME
  )

  for var in ${vars[@]}
  do
    echo_v ${var}
  done
}

find_uid()
{
  if [ -f ${PACKAGES} ]
  then
    for PACKAGE in ${1}
    do
      uid=$(awk "/^${PACKAGE} /{print \$2}" ${PACKAGES})
      if [ ! -z ${uid} ] && ! $(echo "${2}" | grep -q ${uid})
      then
        echo -n "${uid} " >> ${home_path}/.uid
      fi
    done
  fi
  echo "${2} " >> ${home_path}/.uid
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
  SERVER_ADDR="$(find_configuration SERVER_ADDR)"
  ALLOW_IP="$(find_configuration ALLOW_IP)"
  ALLOW_IPv6="$(find_configuration ALLOW_IPv6)"
  ENABLE_IPv6="$(find_configuration ENABLE_IPv6)"
  PACKAGES="$(find_configuration PACKAGES)"
  ALLOW_PACKAGES="$(find_configuration ALLOW_PACKAGES)"
  ALLOW_UDP_PACKAGES="$(find_configuration ALLOW_UDP_PACKAGES)"
  ALLOW_ALL_UID="$(find_configuration ALLOW_ALL_UID)"
  ALLOW_UDP_UID="$(find_configuration ALLOW_UDP_UID)"
  ALLOW_LOCAL_DNS="$(find_configuration ALLOW_LOCAL_DNS)"
  ALLOW_REMOTE_DNS="$(find_configuration ALLOW_REMOTE_DNS)"
  ALLOW_LOCAL_UDP="$(find_configuration ALLOW_LOCAL_UDP)"
  ALLOW_LOCAL_TCP="$(find_configuration ALLOW_LOCAL_TCP)"
  ALLOW_REMOTE_UDP="$(find_configuration ALLOW_REMOTE_UDP)"
  ALLOW_REMOTE_TCP="$(find_configuration ALLOW_REMOTE_TCP)"
  ALLOW_WLAN="$(find_configuration ALLOW_WLAN)"
  ALLOW_LOOKUP="$(find_configuration ALLOW_LOOKUP)"
  ALLOW_UID="$(find_configuration ALLOW_UID)"
  ALLOW_PORT="$(find_configuration ALLOW_PORT)"
  TCP_PORT="$(find_configuration TCP_PORT)"
  MARK="$(find_configuration MARK)"
  TUNDEV="$(find_configuration TUNDEV)"
  TABLE="$(find_configuration TABLE)"
  PREF="$(find_configuration PREF)"
  TUN_ADDR="$(find_configuration TUN_ADDR)"
  WAIT_TIME="$(find_configuration WAIT_TIME)"
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

  local wlan=''
  [ ${ALLOW_WLAN} == 1 ] && wlan='wlan+'
  for LOOKUP in ${ALLOW_LOOKUP} ${wlan}
  do
    # Allow lookup
    iptables -t ${1} ${2} OUTPUT ${3} \
      -w ${WAIT_TIME} \
      -o ${LOOKUP} \
      -j ACCEPT
  done
}

ip46tables()
{
  iptables ${@}
  [ ${ENABLE_IPv6} == 1 ] && ip6tables ${@}
}

ip46route()
{
  ip -4 route ${@}
  [ ${ENABLE_IPv6} == 1 ] && ip -6 route ${@}
}

ip46rule()
{
  ip -4 rule ${@}
  [ ${ENABLE_IPv6} == 1 ] && ip -6 rule ${@}
}

xray_final_rule()
{
  for PROTO in tcp udp
  do
    ip46tables -t mangle -${1} XRAY \
      -p ${PROTO} \
      -j TPROXY \
      --on-port 20801 --tproxy-mark ${MARK}
    ip46tables -t mangle -${1} XRAY_MASK \
      -p ${PROTO} \
      -j MARK --set-mark ${MARK}
  done
}

xray_rule()
{
  ip46rule ${1} fwmark ${MARK} lookup ${TABLE} pref ${PREF}
  ip46route ${1} local default dev lo table ${TABLE}

  ip46tables -t mangle -${2} XRAY \
    -p udp --dport 67:68 \
    -j RETURN

  [ ${ALLOW_REMOTE_UDP} == 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY \
      -p udp ! --dport 53 \
      -m mark ! --mark ${MARK} \
      -j RETURN
  [ ${ALLOW_LOCAL_UDP} == 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY_MASK \
      -p udp ! --dport 53 \
      -j RETURN
  [ ${ALLOW_REMOTE_TCP} == 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY \
      -p tcp \
      -m mark ! --mark ${MARK} \
      -j RETURN
  [ ${ALLOW_LOCAL_TCP} == 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY_MASK \
      -p tcp \
      -j RETURN

  for PROTO in tcp udp
  do
    [ ${ALLOW_REMOTE_DNS} == 1 ] && \
      ip46tables -t mangle -${2} XRAY \
        -p ${PROTO} --dport 53 \
        -m mark ! --mark ${MARK} \
        -j RETURN

    [ ${ALLOW_LOCAL_DNS} == 1 ] && \
      ip46tables -t mangle -${2} XRAY_MASK \
        -p ${PROTO} --dport 53 \
        -j RETURN

    ip46tables -t mangle -${2} XRAY \
      -p ${PROTO} --dport 53 \
      -j TPROXY --on-port 20801 --tproxy-mark ${MARK}

    ip46tables -t mangle -${2} XRAY_MASK \
      -p ${PROTO} --dport 53 \
      -j MARK --set-mark ${MARK}
  done

  for IP in ${ALLOW_IP}
  do
    iptables -t mangle -${2} XRAY \
      -d ${IP} -j RETURN
    iptables -t mangle -${2} XRAY_MASK \
      -d ${IP} -j RETURN
  done

  if [ ${ENABLE_IPv6} == 1 ]
  then
    for IP in ${ALLOW_IPv6}
    do
      ip6tables -t mangle -${2} XRAY \
        -d ${IP} -j RETURN
      ip6tables -t mangle -${2} XRAY_MASK \
        -d ${IP} -j RETURN
    done
  fi

  [ ${ALLOW_WLAN} == 1 ] && \
    ip46tables -t mangle -${2} OUTPUT \
      -o wlan+ \
      -j ACCEPT

  for UID in ${ALLOW_ALL_UID}
  do
    [ -z ${UID} ] || \
      ip46tables -t mangle -${2} XRAY_MASK \
        -m owner --uid ${UID} -j RETURN
  done
  for UID in ${ALLOW_UDP_UID}
  do
    [ -z ${UID} ] || \
      ip46tables -t mangle -${2} XRAY_MASK \
        -p udp -m owner --uid ${UID} -j RETURN
  done

  xray_final_rule ${2}
  ip46tables -t mangle -${2} PREROUTING \
    -p tcp \
    -m socket -j ACCEPT
  for PROTO in tcp udp
  do
    ip46tables -t mangle \
      -${2} PREROUTING \
      -w 2 \
      -p ${PROTO} -j XRAY
    ip46tables -t mangle \
      -${2} OUTPUT \
      -w 2 \
      -p ${PROTO} \
      -m owner ! --gid ${GID} -j XRAY_MASK
  done
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
  ( [ ${ALLOW_LOCAL_UDP} == 1 ] || [ ${ALLOW_REMOTE_UDP} == 1 ] ) && \
    iptables -t mangle ${1} OUTPUT ${2} \
    -w ${WAIT_TIME} \
    -p udp \
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
  [ ${ALLOW_LOCAL_TCP} == 1 ] || iptables -t nat ${1} OUTPUT \
    -w ${WAIT_TIME} \
    -p tcp \
    -j REDIRECT \
    --to ${TCP_PORT}
  # iptables -t nat ${1} OUTPUT -w ${WAIT_TIME} -p udp \
    # --dport 53 -j REDIRECT --to 65053

  [ ${ALLOW_LOCAL_UDP} == 1 ] && iptables -t nat ${1} OUTPUT \
    -w ${WAIT_TIME} \
    -p udp \
    -j ACCEPT

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
  [ ${ALLOW_REMOTE_TCP} == 1 ] || iptables -t nat ${1} PREROUTING \
    -w ${WAIT_TIME} \
    -p tcp \
    -j REDIRECT \
    --to ${TCP_PORT}
  # iptables -t nat ${1} PREROUTING -w ${WAIT_TIME} \
    # -p udp --dport 53 -j REDIRECT --to 65053

  [ ${ALLOW_REMOTE_UDP} == 1 ] && iptables -t mangle ${1} FORWARD \
    -w ${WAIT_TIME} \
    -p udp \
    -j ACCEPT

  # Allow forward DNS network
  iptables -t mangle ${1} FORWARD \
    -w ${WAIT_TIME} \
    -p udp \
    --dport 53 \
    -j ACCEPT
  # End proxy forward
}

xray_open() {
  generate_uid
  load_configuration

  ${home_path}/busybox nohup \
    ${home_path}/busybox setuidgid 0:${GID} \
    ${home_path}/xray run \
    -c ${home_path}/config.json 2>&1 > ${home_path}/xray.log &
  ${home_path}/thread_socket \
    -p ${TCP_PORT} \
    -u ${ALLOW_UID} \
    -r ${SERVER_ADDR} \
    -d &> ${home_path}/sock.log
  ip46tables -t mangle -N XRAY
  ip46tables -t mangle -N XRAY_MASK
  xray_rule add A

  [ ${ENABLE_IPv6} == 0 ] && ip -6 rule add unreachable pref ${PREF} # Deny IPV6

  mv ${0%/*}/disabled ${0%/*}/enabled && echo "xray" > ${0%/*}/enabled
  echo -e "\x1b[92mXray Done.\x1b[0m"
  exit 0
}

xray_close() {
  load_configuration

  xray_rule del D
  ip46tables -t mangle -X XRAY
  ip46tables -t mangle -X XRAY_MASK

  [ ${ENABLE_IPv6} == 0 ] && ip -6 rule del pref ${PREF} # Allow IPV6

  killall xray \
    thread_socket

  rm -f ${home_path}/.uid
  mv ${0%/*}/enabled ${0%/*}/disabled
}

tiny_open() {
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo 1 > /proc/sys/net/ipv4/ip_dynaddr

  generate_uid

  create_tun

  ip -6 rule add unreachable pref ${PREF}
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

  ip -6 rule del pref ${PREF}
  killall thread_socket

  tiny_rule_1 -D

  tiny_rule_2 -D ACCEPT

  rm -f ${home_path}/.uid
  mv ${0%/*}/enabled ${0%/*}/disabled
}

close() {
  case $(cat ${0%/*}/enabled) in
    'thread_socket')
      tiny_close
      ;;
    'xray')
      xray_close
      ;;
    *)
      echo 'Undefined error.'
      exit 127
  esac
}

if [ -f ${0%/*}/disabled ]
then
  if [ ${#} -eq 1 ]
  then
    case ${1} in
      't')
        tiny_open
        ;;
      'x')
        xray_open
        ;;
      's')
        echo 'MLKit is stopped.'
        exit 0
        ;;
      *)
        echo "Undefined core."
        exit -1
    esac
  else
    echo "Need a parameter of core."
    exit -3
  fi
elif [ -f ${0%/*}/enabled ]
then
  if [ ${#} -le 2 ]
  then
    status=$(cat ${0%/*}/enabled)
    case ${1} in
      't')
        if [ 'thread_socket' == ${status} ]
        then
          tiny_close
          exit 0
        else
          close
          tiny_open
        fi
        ;;
      'x')
        if [ 'xray' == ${status} ]
        then
          xray_close
          exit 0
        else
          close
          xray_open
        fi
        ;;
      's')
        echo "MLKit is running. (${status})"
        exit 0
        ;;
      *)
        echo "Core selected is invalid."
    esac
  else
    echo "Need a parameter of core."
    exit -3
  fi
else
  echo "Undefined error."
  exit 1
fi
exit 127

