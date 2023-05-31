#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查Global Cache服务
# Author: beinggod
# Create: 2023-5-31
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
set "+e"

function gc_running_check()
{
    globalcache_log "------------globalcache running check start------------" WARN

    local state=$(systemctl status globalcache | grep -oe "running" | wc -l)
    if [ $state -eq 0 ]; then
        globalcache_log "------------globalcache running check failed!------------" FATAL 
    fi

    globalcache_log "------------globalcache running check end------------" WARN
}

function main()
{
    gc_running_check
}
main