#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 内存使用率
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

#  读取内存信息
function main()
{
    free | grep -oe "[0-9]*" # 内存以Byte为单位
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read mem usage failed!" ERROR && return 1
}
main
