#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 磁盘IO信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# @brief 读取磁盘IO信息
function main()
{
    iostat | grep -v '^[[:space:]]*$' | grep -v "dm"
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read disk io failed!" ERROR && return 1
}
main




