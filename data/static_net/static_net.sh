#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 静态网络信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "-e"

# @brief 读取静态网卡信息
function main()
{
    ip addr
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read static net failed!" ERROR && return 1
}
main
