#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache compile script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
source $SCRIPT_HOME/../liboath_check.sh 
source $SCRIPT_HOME/../zookeeper_check.sh


# 检查cephlib是否已经编译过
cephlib_uncompiled="false"
function cephlib_compile_check()
{
    globalcache_log "------------cephlib compile check start------------" WARN
    if [ ! -f "cephlib-release-oe1.tar.gz" ]; then
        cephlib_uncompiled="true"
    fi

    if [ ! -f "/home/server/ceph-14.2.8/build/lib/libceph-common.so" ]; then
        cephlib_uncompiled="true"
    fi

    if [ "$cephlib_uncompiled" == "true" ]; then
        globalcache_log "cephlib need compile." FATAL 
    else
        globalcache_log "cephlib has been compiled." INFO
    fi
    globalcache_log "------------cephlib compile check end------------" WARN
}

# 检查globalcache_adaptor是否已经编译过
globalcache_adaptor_uncompiled="false"
function globalcache_adaptor_compile_check()
{
    globalcache_log "------------globalcache_adaptor compile check start------------" WARN
    if [ ! -f "globalcache-adaptorlib-release-oe1.tar.gz" ]; then
        globalcache_adaptor_uncompiled="true"
    fi

    if [ "$globalcache_adaptor_uncompiled" == "true" ]; then
        globalcache_log "globalcache_adaptor need to compile." FATAL 
    else
        globalcache_log "globalcache_adaptor has been compiled." WARN
    fi
    globalcache_log "------------globalcache_adaptor compile check end------------" WARN
}

# 检查server
function compile_server_check()
{
    globalcache_log "------------server check start------------" WARN
    cephlib_compile_check
    globalcache_adaptor_compile_check
    globalcache_log "------------server check end------------" WARN
}

function main()
{
cd /home
    compile_liboath_check # 检查liboath
    compile_zookeeper_check # 检查zookeeper
    compile_client_check # 检查client

    realhostname=$(hostname)
    if [ $(echo $realhostname | grep "ceph" | wc -l) -eq 1 ]; then
        compile_server_check # 检查server
    fi
}
main