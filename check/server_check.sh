#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install server script
# Author: xc
# Create: 2022-04-01
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

    if [ $(systemctl --all --type service | grep "globalcache.service" | wc -l) -ne 1 ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check gcache service failed!" FATAL
    fi

    if [ $(systemctl --all --type service | grep "ccm.service" | wc -l) -ne 1 ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check ccm service failed!" FATAL
    fi

    globalcache_log "------------server globalcache check end------------" WARN
}

function main()
{
cd /home
    # server_zookeeper_check # 检查服务端zookeeper
    server_globalcache_check # 检查服务端globalcache
}
main