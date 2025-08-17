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

ALLOW_IPv6="::1/128 fe80::/10"

ENABLE_IPv6=0

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
TPROXY_PORT=20801
MARK=10086
GID=10086
TUNDEV='tunDev'
TABLE=101
PREF=100
TUN_ADDR='172.24.0.1/30'
WAIT_TIME=3

echo_v()
{
  eval "local value=\"\$${1}\""
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
    TPROXY_PORT
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
  TPROXY_PORT="$(find_configuration TPROXY_PORT)"
  MARK="$(find_configuration MARK)"
  TUNDEV="$(find_configuration TUNDEV)"
  TABLE="$(find_configuration TABLE)"
  PREF="$(find_configuration PREF)"
  TUN_ADDR="$(find_configuration TUN_ADDR)"
  WAIT_TIME="$(find_configuration WAIT_TIME)"
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

xray_rule()
{
  ip46rule ${1} fwmark ${MARK} table ${TABLE} pref ${PREF}
  ip46route ${1} local default dev lo table ${TABLE}

  ip46tables -t mangle -${2} XRAY_MASK \
    -m owner --gid ${GID} \
    -j RETURN

  ip46tables -t mangle -${2} XRAY_MASK \
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

  if [ ${ALLOW_REMOTE_DNS} == 1 ] || [ "${3}" == 'tiny' ]
  then
    ip46tables -t mangle -${2} XRAY \
      -p udp --dport 53 \
      -m mark ! --mark ${MARK} \
      -j RETURN
  fi
  if [ ${ALLOW_LOCAL_DNS} == 1 ] || [ "${3}" == 'tiny' ]
  then
    ip46tables -t mangle -${2} XRAY_MASK \
      -p udp --dport 53 \
      -j RETURN
  else
    ip46tables -t mangle -${2} XRAY_MASK \
      -p udp --dport 53 \
      -j MARK --set-mark ${MARK}
  fi
  ip46tables -t mangle -${2} XRAY \
    -p udp --dport 53 \
    -j TPROXY \
    --on-port ${4} --tproxy-mark ${MARK}

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
        -m owner --uid ${UID} \
        -j RETURN
  done
  for UID in ${ALLOW_UDP_UID}
  do
    [ -z ${UID} ] || \
      ip46tables -t mangle -${2} XRAY_MASK \
        -p udp \
        -m owner --uid ${UID} \
        -j RETURN
  done

  [ "${3}" == 'tiny' ] && \
    ip46tables -t mangle -${2} XRAY_MASK \
      -p udp \
      -j DROP

  ip46tables -t mangle -${2} DIVERT \
    -p tcp \
    -j MARK --set-mark ${MARK}
  ip46tables -t mangle -${2} DIVERT \
    -p tcp \
    -j ACCEPT
  ip46tables -t mangle -${2} PREROUTING \
    -p tcp \
    -m socket \
    -j DIVERT

  for PROTO in tcp udp
  do
    ip46tables -t mangle -${2} XRAY \
      -p ${PROTO} \
      -j TPROXY \
      --on-port ${4} --tproxy-mark ${MARK}
    ip46tables -t mangle -${2} XRAY_MASK \
      -p ${PROTO} \
      -j MARK --set-mark ${MARK}

    ip46tables -t mangle \
      -${2} PREROUTING \
      -w ${WAIT_TIME} \
      -p ${PROTO} \
      -j XRAY
    ip46tables -t mangle \
      -${2} OUTPUT \
      -w ${WAIT_TIME} \
      -p ${PROTO} \
      -j XRAY_MASK
  done
}

core_open()
{
  mv ${0%/*}/disabled ${0%/*}/enabled
  [ 'S' == "${1}" ] \
    && echo 'sing-box' > ${0%/*}/enabled \
    || echo 'xray' > ${0%/*}/enabled

  generate_uid
  load_configuration

  if [ "${1}" == 'S' ]
  then
    ${home_path}/busybox nohup \
      ${home_path}/busybox setuidgid 0:${GID} \
      ${home_path}/sing-box run \
      -c ${home_path}/config_sing-box.json \
      -D ${home_path} \
      2>&1 > ${home_path}/core.log &
  else
    ${home_path}/busybox nohup \
      ${home_path}/busybox setuidgid 0:${GID} \
      ${home_path}/xray run \
      -c ${home_path}/config_xray.json \
      2>&1 > ${home_path}/core.log &
  fi
  ${home_path}/thread_socket \
    -p ${TCP_PORT} \
    -u ${ALLOW_UID} \
    -r ${SERVER_ADDR} \
    -d &> ${home_path}/sock.log

  ip46tables -t mangle -N XRAY
  ip46tables -t mangle -N XRAY_MASK
  ip46tables -t mangle -N DIVERT
  xray_rule add A xray ${TPROXY_PORT}

  [ ${ENABLE_IPv6} == 0 ] && \
    ip -6 rule add unreachable pref ${PREF} # Deny IPV6

  [ 'S' == "${1}" ] \
    && echo -e "\x1b[92mSing-box Done.\x1b[0m" \
    || echo -e "\x1b[92mXray Done.\x1b[0m"
  exit 0
}

core_close() {
  load_configuration

  xray_rule del D xray ${TPROXY_PORT}
  ip46tables -t mangle -X XRAY
  ip46tables -t mangle -X XRAY_MASK
  ip46tables -t mangle -X DIVERT

  [ ${ENABLE_IPv6} == 0 ] && ip -6 rule del pref ${PREF} # Allow IPV6

  killall thread_socket
  [ 'S' == "${1}" ] \
    && killall sing-box \
    || killall xray

  rm -f ${home_path}/.uid
  mv ${0%/*}/enabled ${0%/*}/disabled
}

tiny_open() {
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo 1 > /proc/sys/net/ipv4/ip_dynaddr

  mv ${0%/*}/disabled ${0%/*}/enabled && \
    echo 'thread_socket' > ${0%/*}/enabled

  generate_uid
  load_configuration

  # create_tun

  ip -6 rule add unreachable pref ${PREF}
  ${home_path}/thread_socket \
    -p ${TCP_PORT} \
    -u 0 \
    -r ${SERVER_ADDR} \
    -d &> ${home_path}/sock.log

  ip46tables -t mangle -N XRAY
  ip46tables -t mangle -N XRAY_MASK
  ip46tables -t mangle -N DIVERT
  xray_rule add A tiny ${TCP_PORT}

  echo -e "\x1b[92mTiny Done.\x1b[0m"
  exit 0
}

tiny_close() {
  echo 0 > /proc/sys/net/ipv4/ip_forward
  echo 0 > /proc/sys/net/ipv4/ip_dynaddr

  load_configuration

  ip -6 rule del pref ${PREF}
  killall thread_socket

  xray_rule del D tiny ${TCP_PORT}
  ip46tables -t mangle -X XRAY
  ip46tables -t mangle -X XRAY_MASK
  ip46tables -t mangle -X DIVERT

  rm -f ${home_path}/.uid
  mv ${0%/*}/enabled ${0%/*}/disabled
}

close() {
  case $(cat ${0%/*}/enabled) in
    'thread_socket')
      tiny_close
      ;;
    'xray')
      core_close 'X'
      ;;
    'sing-box')
      core_close 'S'
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
        core_open 'X'
        ;;
      'S')
        core_open "${1}"
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
          core_close 'X'
          exit 0
        else
          close
          core_open 'X'
        fi
        ;;
      'S')
        if [ 'sing-box' == ${status} ]
        then
          core_close "${1}"
          exit 0
        else
          close
          core_open "${1}"
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

