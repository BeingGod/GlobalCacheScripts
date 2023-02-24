#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 系统配置中检测CPU信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
function check_cpu_configuration()
{
  globalcache_log "------------check cpu configuration start------------" WARN

  cpu_info=$(cat /proc/cpuinfo| grep "processor"| wc -l)
  if [[ "$cpu_info" == 96 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check hardware success!" WARN
  elif [[ "$cpu_info" == 128 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check hardware success!" WARN
  else
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check hardware failed,please check your cpu" ERROR
    return 1
  fi

  globalcache_log "------------check cpu configuration end------------" WARN
}
