#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install client script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------

SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

set "-e"

# globalcache安装
function globalcache_install()
{
    globalcache_log "------------globalcache install start------------" WARN

    cd /home
    if [ -f "boostkit-globalcache-ceph-adaptor-release-${VERSION}.oe1.$(uname -m).rpm" ]; then
        rpm -ivh boostkit-globalcache-ceph-adaptor-release-${VERSION}.oe1.$(uname -m).rpm --force
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-ceph-adaptor-release-${VERSION}.oe1.$(uname -m).rpm not exist." ERROR
        return 1
    fi
    source /etc/profile

    if [ -f "fio-3.26.tar.gz" ]; then
        tar -zxvf fio-3.26.tar.gz
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:fio-3.26.tar.gz not exist." ERROR
        return 1
    fi
    cd fio-3.26/
    ./configure
    make && make install
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install fio failed!" ERROR && return 1

    globalcache_log "------------globalcache install end------------" WARN
}

# config_scm_init初始化
function config_scm_init()
{
    globalcache_log "------------config_scm init start------------" WARN

    scp ceph1:/opt/gcache/conf/config_scm.conf /opt/gcache/conf/

    sed -i '/^local_ipv4_addr = .*/d' /opt/gcache/conf/config_scm.conf
    sed -i '/^public_ipv4_addr = .*/d' /opt/gcache/conf/config_scm.conf
    sed -i '/^cluster_ipv4_addr = .*/d' /opt/gcache/conf/config_scm.conf
    sed -i '/^local_port = .*/d' /opt/gcache/conf/config_scm.conf

    globalcache_log "------------config_scm init end------------" WARN
}

# gcache_xml_init初始化
function gcache_xml_init()
{
    globalcache_log "------------gcache.xml init start------------" WARN

    cd /opt/gcache/conf/
    sed -i "s/tls_status>on/tls_status>off/g" gcache.xml

    globalcache_log "------------gcache.xml init end------------" WARN
}

# 安裝client
function client_globalcache_install()
{
    globalcache_log "[------------client globalcache install start------------" WARN

    globalcache_install
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:client install globalcache failed!" ERROR && return 1
    config_scm_init
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:client config scm init failed!" ERROR && return 1
    gcache_xml_init
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:client gcache xml init failed!" ERROR && return 1

    globalcache_log "------------client globalcache install end------------" WARN
}

# 卸载client
function client_globalcache_uninstall()
{
    globalcache_log "------------client globalcache uninstall start------------" WARN

    rpm -e boostkit-globalcache-ceph-adaptor --nodeps
    rm -rf /opt/gcache

    globalcache_log "------------client globalcache uninstall end------------" WARN
}
