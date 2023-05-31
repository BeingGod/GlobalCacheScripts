#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查Client GlobalCache部署情况
# Author: beinggod
# Create: 2023-03-19
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
set "+e"

# 检查gcache部署情况
function client_globalcache_check()
{
    globalcache_log "------------check client gcache start------------" WARN

    if [[ $(yum list installed | grep boostkit-globalcache | wc -l) -eq 0 ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check client gcache failed!" FATAL
    fi

    globalcache_log "------------check client gcache end------------" WARN
}

function main()
{
cd /home
    client_globalcache_check
}
main