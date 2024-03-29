#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 动态网络信息
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

#  读取动态网卡信息
function main()
{
    sar -n DEV 1 1 | grep "Average"
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read dynamic net failed!" ERROR && return 1
}
main
