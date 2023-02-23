#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 报警信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# @brief 读取集群异常状态信息
function main()
{
    echo "alarm show all" | LD_LIBRARY_PATH=/opt/gcache/lib /opt/gcache/bin/alarm_query | sed '1,3d'
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read datadiskpart failed!" ERROR && return 1
}
main
