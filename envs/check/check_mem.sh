#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 系统配置中检测内存信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
function check_mem_configuration()
{
  globalcache_log "------------check mem configuration start------------" WARN

  mem_info=$(free -g | grep Mem | awk '{print $2}')
  if [[ "$mem_info" == 190 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check hardware success!" WARN
  elif [[ "$mem_info" == 254 ]];then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check hardware success!" WARN
  else
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check hardware failed,please check your mem" ERROR
    return 1
  fi

  globalcache_log "------------check mem configuration end------------" WARN
}