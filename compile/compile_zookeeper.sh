#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache compile script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

# 获取zookeeper源码
function zookeeper_prepare()
{
    globalcache_log "------------zookeeper prepare start------------" WARN

    yum install cppunit cppunit-devel hostname autoconf libtool libsysfs automake -y
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install zookeeper dependency failed!" ERROR && return 1
    cd /home
    if [ ! -d "apache-zookeeper-3.6.3" ]; then
        tar -zxvf apache-zookeeper-3.6.3.tar.gz
    else
        globalcache_log "The apache-zookeeper-3.6.3 already exists." INFO
    fi

    globalcache_log "------------zookeeper prepare end------------" WARN
}

# 编译zookeeper-jute
function zookeeper_jute_compile()
{
    globalcache_log "------------zookeeper-jute compile start------------" WARN

    cd apache-zookeeper-3.6.3/zookeeper-jute
    if [ ! -d "target" ]; then
        mvn clean install -DskipTests
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:zookeeper jute compile failed!" ERROR && return 1
    else
        globalcache_log "The zookeeper-jute has been compiled." INFO
    fi
    cd ../../

    globalcache_log "------------zookeeper-jute compile end------------" WARN
}

# 编译zookeeper-c
function zookeeper_c_compile()
{
    globalcache_log "------------zookeeper-c compile start------------" WARN

    cd apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c
    if [ ! -d "target" ]; then
        mvn clean install -DskipTests
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:zookeeper c compile failed!" ERROR && return 1
    else
        globalcache_log "The zookeeper-c has been compiled." INFO
    fi
    cd ../../../

    globalcache_log "------------zookeeper-c compile end------------" WARN
}


# 编译zookeeper
function zookeeper_compile()
{
    globalcache_log "------------zookeeper compile start------------" WARN
    cd /home
    zookeeper_jute_compile
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:zookeeper jute compile failed!" ERROR && return 1
    zookeeper_c_compile
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:zookeeper c compile failed!" ERROR && return 1
    cp /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/include/zookeeper/* /usr/include/
    cp /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/lib/* /usr/lib64/

    globalcache_log "------------zookeeper compile end------------" WARN
}

# 检查zookeeper
function compile_zookeeper_check()
{
    globalcache_log "------------zookeeper check start------------" WARN
    cd /home
    if [ -f "apache-zookeeper-3.6.3.tar.gz" ]; then
        globalcache_log "Apache-zookeeper-3.6.3.tar.gz exists." INFO
    else
        globalcache_log "Apache-zookeeper-3.6.3.tar.gz does not exist." WARN
        globalcache_log "Please upload apache-zookeeper-3.6.3.tar.gz to /home." WARN
    fi

    if [ ! -d "/usr/local/jdk8u282-b08" ]; then
        globalcache_log "The /usr/local/jdk8u282-b08 does not exist." WARN
        globalcache_log "Please check jdk8u282-b08." WARN
    fi

    if [ ! -d "/usr/local/apache-maven-3.6.3" ]; then
        globalcache_log "The /usr/local/apache-maven-3.6.3 does not exist." WARN
        globalcache_log "Please check apache-maven-3.6.3." WARN
    fi

    if [ -d "/home/apache-zookeeper-3.6.3" ]; then
        globalcache_log "The apache-zookeeper-3.6.3 already exists." INFO

        if [ -d "/home/apache-zookeeper-3.6.3/zookeeper-jute/target" ]; then
            globalcache_log "The zookeeper-jute has been compiled." WARN
        else
            globalcache_log "The zookeeper-jute need to compile." WARN
        fi

        if [ -d "/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target" ]; then
            globalcache_log "The zookeeper-c has been compiled." WARN
        else
            globalcache_log "The zookeeper-c need to compile." WARN
        fi

        if [ -d "/home/apache-zookeeper-3.6.3/zookeeper-server/target" ]; then
            globalcache_log "The zookeeper-server has been compiled." WARN
        else
            globalcache_log "The zookeeper-server need to compile." WARN
        fi
    else
        globalcache_log "The apache-zookeeper-3.6.3 does not exist." WARN
    fi

    globalcache_log "------------zookeeper check end------------" WARN
}

# 构建zookeeper
function compile_zookeeper_build()
{
    globalcache_log "------------zookeeper build start------------" WARN
    zookeeper_prepare
    zookeeper_compile
    globalcache_log "------------zookeeper build end------------" WARN
}

# 清理zookeeper
function compile_zookeeper_clean()
{
    globalcache_log "------------zookeeper clean start------------" WARN

    globalcache_log "rm -rf /home/apache-zookeeper-3.6.3" WARN
    rm -rf /home/apache-zookeeper-3.6.3
    globalcache_log "------------uninstall server zookeeper include start------------" WARN
    globalcache_log "rm -rf /usr/include/proto.h" WARN
    rm -rf /usr/include/proto.h
    globalcache_log "rm -rf /usr/include/recordio.h" WARN
    rm -rf /usr/include/recordio.h
    globalcache_log "rm -rf /usr/include/zookeeper.h" WARN
    rm -rf /usr/include/zookeeper.h
    globalcache_log "rm -rf /usr/include/zookeeper.jute.h" WARN
    rm -rf /usr/include/zookeeper.jute.h
    globalcache_log "rm -rf /usr/include/zookeeper_log.h" WARN
    rm -rf /usr/include/zookeeper_log.h
    globalcache_log "rm -rf /usr/includezookeeper_version.h" WARN
    rm -rf /usr/include/zookeeper_version.h
    globalcache_log "------------uninstall server zookeeper include end------------" WARN
    globalcache_log "------------uninstall server zookeeper lib start------------" WARN
    globalcache_log "rm -rf /usr/lib64/libzookeeper_*" WARN
    rm -rf /usr/lib64/libzookeeper_*
    globalcache_log "------------uninstall server zookeeper lib end------------" WARN
    globalcache_log "------------zookeeper clean end------------" WARN
}