#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查Global Cache服务
# Author: beinggod
# Create: 2023-5-31
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
source $SCRIPT_HOME/zookeeper_check.sh # 引入server_zookeeper.sh脚本
set "+e"

# 检查server
function server_globalcache_check()
{
    globalcache_log "------------server globalcache check start------------" WARN

    local state=$(systemctl status globalcache | grep -oe "running" | wc -l)
    if [ $state -eq 0 ]; then
        globalcache_log "------------globalcache service check failed!------------" FATAL 
    fi

    local state=$(systemctl status ccm | grep -oe "running" | wc -l)
    if [ $state -eq 0 ]; then
        globalcache_log "------------ccm service check failed!------------" FATAL 
    fi

    globalcache_log "------------server globalcache check end------------" WARN
}

# 检查globalcache运行状态
function gc_running_check()
{
    globalcache_log "------------globalcache running check start------------" WARN

    local state=$(systemctl status globalcache | grep -oe "GlobalCache Running" | wc -l)
    if [ $state -eq 0 ]; then
        globalcache_log "------------globalcache running check failed!------------" FATAL 
    fi

    globalcache_log "------------globalcache running check end------------" WARN
}

function main()
{
cd /home
    # server_zookeeper_check # 检查服务端zookeeper
    server_globalcache_check # 检查服务端globalcache
    gc_running_check
}
main