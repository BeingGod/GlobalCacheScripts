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
set "+e"

# 获取server源码
function server_prepare()
{
    globalcache_log "------------server prepare start------------" WARN
    mkdir -p server
    mkdir -p server/adaptorlib
    if [ -d "server/ceph-14.2.8" ]; then
        globalcache_log "ceph-14.2.8 does not need to be prepared." INFO
    else
        cp ceph-14.2.8.tar.gz server

        cd server
        tar -zxvf ceph-14.2.8.tar.gz
        cp ../ceph-global-cache-tls.patch ceph-14.2.8
        cd ceph-14.2.8
        patch -p1 < ceph-global-cache-tls.patch
        sed -i "s/-DCMAKE_BUILD_TYPE=Debug/-DCMAKE_BUILD_TYPE=RelWithDebInfo/g" do_cmake.sh

        # patch ceph
        sed -i "22i\#define HAVE_REENTRANT_STRSIGNAL //" src/global/signal_handler.h

        cd ../..
    fi

    if [ -d "server/adaptorlib/ceph-global-cache-adaptor" ]; then
        globalcache_log "ceph-global-cache-adaptor does not need to be prepared." INFO
    else
        tar -xzvf ceph-global-cache-adaptor-T14.tar.gz
        cp -r ceph-global-cache-adaptor-T14 server/adaptorlib/ceph-global-cache-adaptor
        # cd server/adaptorlib
        # git clone https://github.com/666syh/ceph-global-cache-adaptor.git
        # [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:git clone ceph-global-cache-adaptor failed!" ERROR && return 1
        # cd ceph-global-cache-adaptor 
        # git checkout T14
        # cd ../../../
    fi

    globalcache_log "------------server prepare end------------" WARN
}

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

# 编译cephlib
function cephlib_compile()
{
    globalcache_log "------------cephlib compile start------------" WARN

    cephlib_compile_check
    if [ "$cephlib_uncompiled" == "true" ]; then
        cd server/ceph-14.2.8
        sh do_cmake.sh
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:cephlib cmake failed!" ERROR && return 1
        cd build
        make -j64
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:cephlib compile failed!" ERROR && return 1
        mkdir -p ../../../cephlib
        cp lib/libceph-common.so* ../../../cephlib
        cp lib/librados.so* ../../../cephlib
        cp lib/libcls_rgw.so* ../../../cephlib
        cp lib/libcls_lock.so* ../../../cephlib
        cp lib/librbd.so* ../../../cephlib
        cd ../../..
        tar zcvf cephlib-release-oe1.tar.gz cephlib/
    else
        globalcache_log "cephlib does not need to be compiled." INFO
    fi

    globalcache_log "------------cephlib compile end------------" WARN
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

# 编译globalcache_adaptor
function globalcache_adaptor_compile()
{
    globalcache_log "------------globalcache_adaptor compile start------------" WARN

    globalcache_adaptor_compile_check
    if [ "$globalcache_adaptor_uncompiled" == "true" ]; then
        cd server/adaptorlib/ceph-global-cache-adaptor
        export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/opt/gcache_adaptor_compile/third_part/inc/"
        sh build.sh
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache adaptor lib compile failed!" ERROR && return 1
        cd package
        sh globalcache-adaptorlib_pack.sh
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache adaptor lib pack failed!" ERROR && return 1
        cp globalcache-adaptorlib-release-oe1.tar.gz ../../../..
        cd ../../../..
    else
        globalcache_log "globalcache_adaptor does not need to be compiled." FATAL 
    fi

    globalcache_log "------------globalcache_adaptor compile end------------" WARN
}

# 编译server
function server_compile()
{
    globalcache_log "------------server compile start------------" WARN
    cephlib_compile
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph lib compile failed!" ERROR && return 1
    globalcache_adaptor_compile
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache adaptor lib compile failed!" ERROR && return 1
    globalcache_log "------------server compile end------------" WARN
}

# 检查server
function compile_server_check()
{
    globalcache_log "------------server check start------------" WARN
    cephlib_compile_check
    globalcache_adaptor_compile_check
    globalcache_log "------------server check end------------" WARN
}

# 构建server
function compile_server_build()
{
    globalcache_log "------------server build start------------" WARN
    server_prepare
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:server prepare failed!" ERROR && return 1
    server_compile
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:server compile failed!" ERROR && return 1
    globalcache_log "------------server build end------------" WARN
}

# 清理server
function compile_server_clean()
{
    globalcache_log "------------server clean start------------" WARN
    globalcache_log "rm -rf server" WARN
    rm -rf server
    globalcache_log "rm -rf cephlib" WARN
    rm -rf cephlib
    globalcache_log "rm -rf cephlib-release-oe1.tar.gz" WARN
    rm -rf cephlib-release-oe1.tar.gz
    globalcache_log "rm -rf globalcache-adaptorlib-release-oe1.tar.gz" WARN
    rm -rf globalcache-adaptorlib-release-oe1.tar.gz
    globalcache_log "------------server clean end------------" WARN
}
