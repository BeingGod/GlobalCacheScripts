#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ntp客户端 (exclude ceph1)
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

# 配置ntp客户端
function configure_ntp_client()
{
  globalcache_log "------------configure ntp client start------------" WARN

  # 判断ntp是否安装
  yum -y install ntp ntpdate
  
  mv /etc/ntp.conf /etc/ntp.conf.bak

  if [ -f /etc/ntp.conf ]; then
    rm -rf /etc/ntp.conf
  fi

  local server_ip=$(cat /home/script.conf | grep ntp_server | cut -d ' ' -f 2)
  echo "server $server_ip" > /etc/ntp.conf

  # 同步时间
  ntpdate $server_ip 
  hwclock -w

  # 安装crontab定时服务
  yum install -y crontabs

  if [[ $(systemctl status crond | grep -oe "active" | wc -l) -eq 1 ]]; then
    systemctl enable crond.service
    systemctl start crond 
  fi

  # 添加定时任务
  echo "*/10 * * * * /usr/sbin/ntpdate $server_ip" | crontab -     

  globalcache_log "------------configure ntp client end------------" WARN
}

function main()
{
  if [ ! -f "/home/script.conf" ]; then
    globalcache_log "Please generated script config file first" WARN
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi

  configure_ntp_client
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ntp client failed!" ERROR && return 1
}
main