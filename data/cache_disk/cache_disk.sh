#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 缓存盘信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

# 读取集群运行状态
function main()
{
    if [ $(ps -ef | grep "mgrtool" | wc -l) -eq 5 ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read PT failed!" ERROR && return 1
    fi

    # 移除先前执行结果
    rm -rf ${SCRIPT_HOME}/*.log

    local command="ccm list diskList"
    local timestamp=$(date "+%Y%m%d%H%M%S")
    echo $command > "${SCRIPT_HOME}/${timestamp}.log"
    LD_LIBRARY_PATH=/opt/gcache/lib /opt/gcache/bin/mgrtool --no-prompt --script=${SCRIPT_HOME}/${timestamp}.log
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read cluster status failed!" ERROR
}
main

