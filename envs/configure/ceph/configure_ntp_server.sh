#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ntp服务端 (ceph1)
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

# 配置ntp服务端
function configure_ntp_server()
{
  globalcache_log "------------configure ntp server start------------" WARN

  local hostname=$(cat $SCRIPT_HOME/script.conf | grep hostname | cut -d ' ' -f 2)

  # 判断ntp是否安装
  yum -y install ntp ntpdate
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ntp failed!" ERROR && return 1
  
  mv /etc/ntp.conf /etc/ntp.conf.bak

  if [ -f /etc/ntp.conf ]; then
    rm -rf /etc/ntp.conf
  fi

  local server_ip=$(cat $SCRIPT_HOME/script.conf | grep ntp_server | cut -d ' ' -f 2)
  local mask=$(cat $SCRIPT_HOME/script.conf | grep mask | cut -d ' ' -f 2)

  # 更新配置ntpd文件
  echo "restrict 127.0.0.1
restrict ::1
restrict $server_ip mask $mask
server 127.127.1.0
fudge 127.127.1.0
stratum 8"
  cat $SCRIPT_HOME/server_ntp.conf > /etc/ntp.conf

  # 判断ntpd服务是否开启
  if [[ $(systemctl status ntpd | grep active | wc -l) -ne 1 ]]; then
    systemctl start ntpd 
    systemctl enable ntpd 
  fi

  globalcache_log "------------configure ntp server end------------" WARN
}

function main()
{
  if [ ! -f "$SCRIPT_HOME/script.conf" ]; then
    globalcache_log "Please generated script config file first" WARN
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi

  configure_ntp_server
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ntp server failed!" ERROR && return 1
}
main