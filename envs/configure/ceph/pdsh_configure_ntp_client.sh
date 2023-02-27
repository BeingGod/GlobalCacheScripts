#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ntp客户端
#              注意: 该脚本需要使用pdsh调用
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh
source $SCRIPT_HOME/../../../common/pdsh.sh

# 配置ntp客户端
function configure_ntp_client()
{
  globalcache_log "------------configure ntp client start------------" WARN

  # 判断ntp是否安装
  yum -y install ntp ntpdate
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ntp failed!" ERROR && return 1
  
  mv /etc/ntp.conf /etc/ntp.conf.bak

  if [ -f /etc/ntp.conf ]; then
    rm -rf /etc/ntp.conf
  fi

  local server_ip=$(cat $SCRIPT_HOME/script.conf | grep ntp_server | cut -d ' ' -f 2)
  echo "server $server_ip" > /etc/ntp.conf

  # 判断ntpd服务是否开启
  if [[ $(systemctl status ntpd | grep active | wc -l) -ne 1 ]]; then
    systemctl start ntpd 
    systemctl enable ntpd 
  fi

  # 同步时间
  ntpdate ceph1
  hwclock -w

  # 安装crontab定时服务
  yum install -y crontabs
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install crontabs failed!" ERROR && return 1

  if [[ $(systemctl status crond | grep active | wc -l 1) -ne 1 ]]; then
    systemctl enable crond.service
    systemctl start crond 
  fi

  # 添加定时任务
  echo "*/10 * * * * /usr/sbin/ntpdate $server_ip" | crontab -     

  globalcache_log "------------configure ntp client end------------" WARN
}
configure_ntp_client