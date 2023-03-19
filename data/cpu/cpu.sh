#!/bin/bash
#------------------------------------------------------------------------------------
# Description: CPU使用率
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# @brief 读取CPU的闲置率
function main()
{
    mpstat -P ALL | awk  '{print substr($0,length($0)-5)}' | sed '1,3d'
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read cpu usage failed!" ERROR && return 1
}
main
