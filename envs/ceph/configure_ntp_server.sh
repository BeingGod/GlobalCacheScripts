#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ntp服务端 (ceph1)
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

# 配置ntp服务端
function configure_ntp_server()
{
  globalcache_log "------------configure ntp server start------------" WARN

  if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
    sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
  fi

  # 判断ntp是否安装
  yum -y install ntp ntpdate
  
  mv /etc/ntp.conf /etc/ntp.conf.bak

  if [ -f /etc/ntp.conf ]; then
    rm -rf /etc/ntp.conf
  fi

  local server_ip=$(cat /home/script.conf | grep ntp_server | cut -d ' ' -f 2)
  local mask=$(cat /home/script.conf | grep mask | cut -d ' ' -f 2)

  # 更新配置ntpd文件
  echo "restrict 127.0.0.1
restrict ::1
restrict $server_ip mask $mask
server 127.127.1.0
fudge 127.127.1.0
stratum 8" > /etc/ntp.conf

  # 判断ntpd服务是否开启
  if [[ $(systemctl status ntpd | grep -w -oe "active" | wc -l) -eq 0 ]]; then
    systemctl start ntpd 
    systemctl enable ntpd 
  fi

  globalcache_log "------------configure ntp server end------------" WARN
}

function main()
{
  configure_ntp_server
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ntp server failed!" ERROR && return 1
}
main