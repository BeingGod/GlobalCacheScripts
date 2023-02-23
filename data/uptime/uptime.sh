#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 节点在线时间
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# @brief 读取运行时间信息
function main()
{
    local uptime=$(uptime | grep -oe "[0-9] days, [0-9]*:[0-9]*,")
    if [[ -z $uptime ]]; then
       local uptime=$(uptime | grep -oe "[0-9]*:[0-9]*,")
    fi
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read uptime failed!" ERROR && return 1
    echo $uptime
}
main
