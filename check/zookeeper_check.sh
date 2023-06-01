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
set "+e"

# 检查zookeeper
function server_zookeeper_check()
{
    globalcache_log "------------server zookeeper check start------------" WARN

    local state=$(systemctl status zookeeper | grep -oe "active" | wc -l)
    if [ $state -eq 0 ]; then
        globalcache_log "------------zookeeper service check failed!------------" FATAL 
    fi

    globalcache_log "------------server zookeeper check end------------" WARN
}

# 检查zookeeper
function compile_zookeeper_check()
{
    globalcache_log "------------zookeeper check start------------" WARN
    cd /home
    if [ -f "apache-zookeeper-3.6.3.tar.gz" ]; then
        globalcache_log "Apache-zookeeper-3.6.3.tar.gz exists." INFO
    else
        globalcache_log "Apache-zookeeper-3.6.3.tar.gz does not exist." FATAL 
        globalcache_log "Please upload apache-zookeeper-3.6.3.tar.gz to /home." WARN
    fi

    if [ ! -d "/usr/local/jdk8u282-b08" ]; then
        globalcache_log "The /usr/local/jdk8u282-b08 does not exist." FATAL
        globalcache_log "Please check jdk8u282-b08." WARN
    fi

    if [ ! -d "/usr/local/apache-maven-3.6.3" ]; then
        globalcache_log "The /usr/local/apache-maven-3.6.3 does not exist." FATAL
        globalcache_log "Please check apache-maven-3.6.3." WARN
    fi

    if [ -d "/home/apache-zookeeper-3.6.3" ]; then
        globalcache_log "The apache-zookeeper-3.6.3 already exists." INFO

        if [ -d "/home/apache-zookeeper-3.6.3/zookeeper-jute/target" ]; then
            globalcache_log "The zookeeper-jute has been compiled." WARN
        else
            globalcache_log "The zookeeper-jute need to compile." FATAL
        fi

        if [ -d "/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target" ]; then
            globalcache_log "The zookeeper-c has been compiled." WARN
        else
            globalcache_log "The zookeeper-c need to compile." FATAL
        fi
    else
        globalcache_log "The apache-zookeeper-3.6.3 does not exist." FATAL
    fi

    globalcache_log "------------zookeeper check end------------" WARN
}
