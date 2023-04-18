#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 磁盘PG信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

set "-e"

function usage()
{
    echo "$0:usage: <diskId>"
}

# 读取PG
function main()
{
    if [ $(ps -ef | grep "mgrtool" | wc -l) -eq 5 ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read PG failed!" ERROR && return 1
    fi

    local command="ccm show pgViewOnDisk $1"
    local timestamp=$(date "+%Y%m%d%H%M%S")
    echo $command > "${SCRIPT_HOME}/${timestamp}.log"
    LD_LIBRARY_PATH=/opt/gcache/lib /opt/gcache/bin/mgrtool --no-prompt --script=${SCRIPT_HOME}/${timestamp}.log
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read PG failed!" ERROR
    rm -r "${SCRIPT_HOME}/${timestamp}.log"
}
main $1
