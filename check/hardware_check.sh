#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 系统硬件配置检查
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

function mem_conf_check()
{
  globalcache_log "------------check mem configuration start------------" WARN

  mem_info=$(free -g | grep Mem | awk '{print $2}')
  if [[ "$mem_info" -ge 500 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check mem success!" WARN
  else
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check mem failed,please check your mem" FATAL
  fi

  globalcache_log "------------check mem configuration end------------" WARN
}

function cpu_conf_check()
{
  globalcache_log "------------check cpu configuration start------------" WARN

  cpu_info=$(cat /proc/cpuinfo| grep "processor"| wc -l)
  if [[ "$cpu_info" == 96 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check cpu success!" WARN
  elif [[ "$cpu_info" == 128 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check cpu success!" WARN
  else
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check cpu failed,please check your cpu" FATAL
  fi

  globalcache_log "------------check cpu configuration end------------" WARN
}


function main() {
  cpu_conf_check

  mem_conf_check
}
main