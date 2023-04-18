#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 系统硬件配置信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
source $SCRIPT_HOME/check_cpu.sh
source $SCRIPT_HOME/check_mem.sh

function main() {
  check_cpu_configuration
  if [[ $? -ne 0 ]]; then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check cpu failed!" ERROR && return 1
  fi
  check_mem_configuration
  if [[ $? -ne 0 ]]; then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check mem failed!" ERROR && return 2
  fi
}
main