#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 集群状态信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# @brief 读取集群运行状态
function main()
{
    if [ $(ps -ef | grep "mgrtool" | wc -l) -eq 5 ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read cluster status failed!" ERROR && return 1
    fi

    local command="ccm show clusterStatus"
    local timestamp=$(date "+%Y%m%d%H%M%S")
    echo $command > "${SCRIPT_HOME}/${timestamp}.log"
    LD_LIBRARY_PATH=/opt/gcache/lib /opt/gcache/bin/mgrtool --no-prompt --script=${SCRIPT_HOME}/${timestamp}.log
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read cluster status failed!" ERROR && return 1
    rm -r "${SCRIPT_HOME}/${timestamp}.log"
}
main
