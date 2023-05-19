#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查配置文件 
# Author: beinggod
# Create: 2023-5-18
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

function conf_check()
{
  globalcache_log "------------check cluster configuration file start------------" WARN

  if [ $(ls /home | grep -x "nodelist.txt" | wc -l) -ne 1 ]; then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:nodelist.txt not exits,please check your configuration file" FATAL
  fi

  if [ $(ls /home | grep -x "script.conf" | wc -l) -ne 1 ]; then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:script.conf not exits,please check your configuration file" FATAL
  fi

  realhostname=$(hostname)
  if [ $(echo $realhostname | grep "ceph" | wc -l) -eq 1 ]; then
    if [ $(ls /home | grep -x "disklist.txt" | wc -l) -ne 1 ]; then
      globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:disklist.txt not exits,please check your configuration file" FATAL
    fi
  fi

  if [ $(ls /home | grep -x "hostnamelist.txt" | wc -l) -ne 1 ]; then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:hostnamelist.txt not exits,please check your configuration file" FATAL
  fi

  globalcache_log "------------check cluster configuration file end------------" WARN
}

function main()
{
cd /home
  conf_check
}
main