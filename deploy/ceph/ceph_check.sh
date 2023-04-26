#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查Ceph部署情况
# Author: beinggod
# Create: 2023-03-19
#-----------------------------------------------------------------------------------
set -x
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=$SCRIPT_HOME/../../log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

function main()
{
    if ceph -s > /dev/null 2>&1; then
        ceph -s
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph is not deployed!" ERROR && return 1
    fi
}
main