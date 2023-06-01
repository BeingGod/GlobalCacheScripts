#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 节点名称 
# Author: beinggod
# Create: 2023-4-30
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

#  读取内存信息
function main()
{
    echo "$(hostname)"
}
main
