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

# 检查liboath是否已经编译过
liboath_uncompiled="false"
function compile_liboath_check()
{
    globalcache_log "------------liboath compile check start------------" WARN
    
    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/liboath-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/liboath-devel-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/libpskc-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/libpskc-devel-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/oath-toolkit-debuginfo-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/oath-toolkit-debugsource-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/oathtool-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/pam_oath-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/$(uname -m)/pskctool-2.6.5-3.$(uname -m).rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/noarch/liboath-doc-2.6.5-3.noarch.rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ ! -f "/root/rpmbuild/RPMS/noarch/libpskc-doc-2.6.5-3.noarch.rpm" ]; then
        liboath_uncompiled="true"
    fi

    if [ "$liboath_uncompiled" == "true" ]; then
        globalcache_log "Liboath need compile" FATAL 
    else
        globalcache_log "Liboath has been compiled." WARN 
    fi

    globalcache_log "------------liboath compile check end------------" WARN
}