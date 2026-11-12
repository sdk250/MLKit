#!/bin/sh
# Powered by sdk250
set -e

if [ "$(id -u)" != "0" ]
then
  echo "Must run as root!"
  exit 1
fi

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

ALLOW_IPv6="::1/128 \
  fe80::/10"

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
GID=3004
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
  printf '%s\n%s\n\n' \
    '# This file is automatical genrated by `mlk.sh`' \
    '# DO NOT edit it' > ${home_path}/.uid

  printf 'ALLOW_ALL_UID=' >> ${home_path}/.uid
  find_uid "${ALLOW_PACKAGES}" "${ALLOW_ALL_UID}"
  printf 'ALLOW_UDP_UID=' >> ${home_path}/.uid
  find_uid "${ALLOW_UDP_PACKAGES}" "${ALLOW_UDP_UID}"

  # Saving configuration
  local vars="SERVER_ADDR \
      ALLOW_IP \
      ALLOW_IPv6 \
      ENABLE_IPv6 \
      PACKAGES \
      ALLOW_PACKAGES \
      ALLOW_UDP_PACKAGES \
      ALLOW_LOCAL_DNS \
      ALLOW_REMOTE_DNS \
      ALLOW_LOCAL_UDP \
      ALLOW_LOCAL_TCP \
      ALLOW_REMOTE_UDP \
      ALLOW_REMOTE_TCP \
      ALLOW_WLAN \
      ALLOW_LOOKUP \
      ALLOW_UID \
      ALLOW_PORT \
      TCP_PORT \
      TPROXY_PORT \
      MARK \
      TUNDEV \
      TABLE \
      PREF \
      TUN_ADDR \
      WAIT_TIME"

  for var in ${vars}
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
      if [ -n "${uid}" ] && ! echo "${2}" | grep -qw "${uid}"
      then
        printf '%s ' "${uid}" >> ${home_path}/.uid
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
  # .uid 不存在时（例如被手动删除）保留脚本中的默认值，避免变量被清空
  [ -f ${home_path}/.uid ] || return 0

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
  iptables -w ${WAIT_TIME} ${@}
  if [ "${ENABLE_IPv6}" = 1 ]
  then
    ip6tables -w ${WAIT_TIME} ${@}
  fi
}

ip46route()
{
  ip -4 route ${@}
  if [ "${ENABLE_IPv6}" = 1 ]
  then
    ip -6 route ${@}
  fi
}

ip46rule()
{
  ip -4 rule ${@}
  if [ "${ENABLE_IPv6}" = 1 ]
  then
    ip -6 rule ${@}
  fi
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

  local FOP="D"
  if [ "${2}" = "A" ]
  then
    FOP="I"
  fi
  ip46tables -t filter -${FOP} INPUT \
    -m mark --mark ${MARK} \
    -j ACCEPT
  ip46tables -t filter -${FOP} FORWARD \
    -m mark --mark ${MARK} \
    -j ACCEPT

  [ "${ALLOW_REMOTE_UDP}" = 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY \
      -p udp ! --dport 53 \
      -m mark ! --mark ${MARK} \
      -j RETURN
  [ "${ALLOW_LOCAL_UDP}" = 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY_MASK \
      -p udp ! --dport 53 \
      -j RETURN
  [ "${ALLOW_REMOTE_TCP}" = 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY \
      -p tcp \
      -m mark ! --mark ${MARK} \
      -j RETURN
  [ "${ALLOW_LOCAL_TCP}" = 1 ] && \
    ip46tables -t mangle \
      -${2} XRAY_MASK \
      -p tcp \
      -j RETURN

  if [ "${ALLOW_REMOTE_DNS}" = 1 ] || [ "${3}" = 'tiny' ]
  then
    ip46tables -t mangle -${2} XRAY \
      -p udp --dport 53 \
      -m mark ! --mark ${MARK} \
      -j RETURN
  fi
  if [ "${ALLOW_LOCAL_DNS}" = 1 ] || [ "${3}" = 'tiny' ]
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
      -w ${WAIT_TIME} \
      -d ${IP} -j RETURN
    iptables -t mangle -${2} XRAY_MASK \
      -w ${WAIT_TIME} \
      -d ${IP} -j RETURN
  done

  if [ "${ENABLE_IPv6}" = 1 ]
  then
    for IP in ${ALLOW_IPv6}
    do
      ip6tables -t mangle -${2} XRAY \
        -d ${IP} -j RETURN
      ip6tables -t mangle -${2} XRAY_MASK \
        -d ${IP} -j RETURN
    done
  fi

  [ "${ALLOW_WLAN}" = 1 ] && \
    ip46tables -t mangle -${2} OUTPUT \
      -o wlan+ \
      -j ACCEPT

  for U in ${ALLOW_ALL_UID}
  do
    [ -z ${U} ] || \
      ip46tables -t mangle -${2} XRAY_MASK \
        -m owner --uid ${U} \
        -j RETURN
  done
  for U in ${ALLOW_UDP_UID}
  do
    [ -z ${U} ] || \
      ip46tables -t mangle -${2} XRAY_MASK \
        -p udp \
        -m owner --uid ${U} \
        -j RETURN
  done

  [ "${3}" = 'tiny' ] && \
    ip46tables -t mangle -${2} XRAY_MASK \
      -p udp \
      -j DROP

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
      -${FOP} PREROUTING \
      -w ${WAIT_TIME} \
      -p ${PROTO} \
      -j XRAY
    ip46tables -t mangle \
      -${2} OUTPUT \
      -w ${WAIT_TIME} \
      -p ${PROTO} \
      -j XRAY_MASK
  done

  ip46tables -t mangle -${2} DIVERT \
    -p tcp \
    -j MARK --set-mark ${MARK}
  ip46tables -t mangle -${2} DIVERT \
    -p tcp \
    -j ACCEPT
  ip46tables -t mangle -${FOP} PREROUTING \
    -p tcp \
    -m socket \
    -j DIVERT
}

# 尽力清理：规则/进程可能本来就不存在（例如断电重启后），
# 任何一步失败都不能中断脚本，因此每条命令都以 `|| true` 结尾。
# 以 `|| true` 方式调用 xray_rule 时，其内部的 set -e 不生效，每条删除都会被尝试。
clean_rules()
{
  xray_rule del D ${1} ${2} || true
  ip46tables -t mangle -X XRAY || true
  ip46tables -t mangle -X XRAY_MASK || true
  ip46tables -t mangle -X DIVERT || true
}

# 开启过程中任一命令失败时（set -e 触发退出），撤销已做的改动，保持 disabled 状态
rollback()
{
  printf '\033[91mStart failed, rolling back.\033[0m\n' >&2
  clean_rules ${1} ${2} > /dev/null 2>&1
  ip -6 rule del pref ${PREF} > /dev/null 2>&1 || true
  killall thread_socket > /dev/null 2>&1 || true
  killall xray > /dev/null 2>&1 || true
  rm -f ${home_path}/.uid
}

core_open()
{
  generate_uid
  load_configuration

  ulimit -n 32768

  trap "rollback xray ${TPROXY_PORT}" EXIT

  # 先建链和规则：-N 失败（链已存在，说明有残留规则）会立即退出并回滚
  ip46tables -t mangle -N XRAY
  ip46tables -t mangle -N XRAY_MASK
  ip46tables -t mangle -N DIVERT
  xray_rule add A xray ${TPROXY_PORT}

  if [ "${ENABLE_IPv6}" = 0 ]
  then
    ip -6 rule add unreachable pref ${PREF} # Deny IPV6
  fi

  ${home_path}/run ${GID} \
    ${home_path}/xray run \
    -c ${home_path}/config_xray.json \
    > ${home_path}/core.log 2>&1 &
  ${home_path}/thread_socket \
    -p ${TCP_PORT} \
    -u ${ALLOW_UID} \
    -r ${SERVER_ADDR} \
    -d > ${home_path}/sock.log 2>&1

  # 全部成功后才记录状态
  trap - EXIT
  mv ${0%/*}/disabled ${0%/*}/enabled
  echo 'xray' > ${0%/*}/enabled

  printf '\033[92mXray Done.\033[0m\n'
}

core_close()
{
  load_configuration

  clean_rules xray ${TPROXY_PORT}

  if [ "${ENABLE_IPv6}" = 0 ]
  then
    ip -6 rule del pref ${PREF} || true # Allow IPV6
  fi

  killall thread_socket || true
  killall xray || true

  rm -f ${home_path}/.uid
  mv ${0%/*}/enabled ${0%/*}/disabled
}

tiny_open()
{
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo 1 > /proc/sys/net/ipv4/ip_dynaddr

  generate_uid
  load_configuration

  # create_tun

  trap "rollback tiny ${TCP_PORT}" EXIT

  ip46tables -t mangle -N XRAY
  ip46tables -t mangle -N XRAY_MASK
  ip46tables -t mangle -N DIVERT
  xray_rule add A tiny ${TCP_PORT}

  ip -6 rule add unreachable pref ${PREF}
  ${home_path}/thread_socket \
    -p ${TCP_PORT} \
    -u 0 \
    -r ${SERVER_ADDR} \
    -d > ${home_path}/sock.log 2>&1

  # 全部成功后才记录状态
  trap - EXIT
  mv ${0%/*}/disabled ${0%/*}/enabled
  echo 'thread_socket' > ${0%/*}/enabled

  printf '\033[92mTiny Done.\033[0m\n'
}

tiny_close()
{
  echo 0 > /proc/sys/net/ipv4/ip_forward
  echo 0 > /proc/sys/net/ipv4/ip_dynaddr

  load_configuration

  ip -6 rule del pref ${PREF} || true
  killall thread_socket || true

  clean_rules tiny ${TCP_PORT}

  rm -f ${home_path}/.uid
  mv ${0%/*}/enabled ${0%/*}/disabled
}

# 按状态文件中记录的核心关闭
close()
{
  case "${1}" in
    'thread_socket') tiny_close ;;
    'xray')          core_close ;;
    *)
      echo "Unknown status: ${1}"
      exit 127
      ;;
  esac
}

usage()
{
  echo "Usage: ${0} <t|x|s>"
  echo '  t  启动/关闭 thread_socket 模式'
  echo '  x  启动/关闭 xray 模式'
  echo '  s  查看运行状态'
  exit 2
}

[ ${#} -eq 1 ] || usage

# 当前状态：enabled 文件中记录的核心名；disabled 时为空
if [ -f ${0%/*}/enabled ]
then
  status=$(cat ${0%/*}/enabled)
elif [ -f ${0%/*}/disabled ]
then
  status=''
else
  echo "Undefined error: neither enabled nor disabled exists."
  exit 1
fi

# "<当前状态>:<参数>"
#   相同核心再次执行 → 关闭；其他核心在运行 → 先关闭再切换；未运行 → 直接启动
case "${status}:${1}" in
  *:s)
    [ -n "${status}" ] \
      && echo "MLKit is running. (${status})" \
      || echo 'MLKit is stopped.'
    ;;
  thread_socket:t | xray:x)
    close "${status}"
    ;;
  :t)
    tiny_open
    ;;
  :x)
    core_open
    ;;
  *:t)
    close "${status}"
    tiny_open
    ;;
  *:x)
    close "${status}"
    core_open
    ;;
  *)
    usage
    ;;
esac
