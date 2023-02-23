#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 磁盘PT信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "-e"

function usage()
{
    echo "$0:usage: <diskId>"
}

# @brief 读取PT
function main()
{
    if [ $(ps -ef | grep "mgrtool" | wc -l) -eq 5 ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read PT failed!" ERROR && return 1
    fi

    local command="ccm show ptViewOnDisk $1"
    local timestamp=$(date "+%Y%m%d%H%M%S")
    echo $command > "${SCRIPT_HOME}/${timestamp}.log"
    LD_LIBRARY_PATH=/opt/gcache/lib /opt/gcache/bin/mgrtool --no-prompt --script=${SCRIPT_HOME}/${timestamp}.log
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read PT failed!" ERROR && return 1
    rm -r "${SCRIPT_HOME}/${timestamp}.log"
}
main $1
