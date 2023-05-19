#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查Ceph部署情况
# Author: beinggod
# Create: 2023-03-19
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

function ceph_check()
{
    globalcache_log "------------check ceph start------------" WARN

    if ceph -s > /dev/null 2>&1; then
        ceph -s
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check ceph failed!" FATAL
    fi

    globalcache_log "------------check ceph start------------" WARN
}

function main()
{
cd /home
    ceph_check
}
main