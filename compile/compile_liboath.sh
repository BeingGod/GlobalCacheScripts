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

# 获取liboath源码
function liboath_prepare()
{
    globalcache_log "------------liboath prepare start------------" WARN

    yum install git -y
    [[ $? -ne 0 ]] && log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install git failed!" ERROR && return 1
    git config --global http.sslVerify false

    cd /root    
    if [ ! -d "/root/oath-toolkit" ]; then
        git clone https://gitee.com/src-openeuler/oath-toolkit.git
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The oath-toolkit already exists." INFO
    fi
        
    yum install wget rpmdevtools gtk-doc pam-devel xmlsec1-devel libtool libtool-ltdl-devel createrepo cmake -y
    [[ $? -ne 0 ]] && log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install liboath dependency failed!" ERROR && return 1
    rpmdev-setuptree

    if [ -f "/root/rpmbuild/SOURCES/0001-oath-toolkit-2.6.5-lockfile.patch" ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The 0001-oath-toolkit-2.6.5-lockfile.patch already exists." INFO
    else
        cp oath-toolkit/0001-oath-toolkit-2.6.5-lockfile.patch /root/rpmbuild/SOURCES
    fi
        
    if [ -f "/root/rpmbuild/SOURCES/oath-toolkit-2.6.5.tar.gz" ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The oath-toolkit-2.6.5.tar.gz already exists." INFO
    else
        cp oath-toolkit/oath-toolkit-2.6.5.tar.gz /root/rpmbuild/SOURCES
    fi

    if [ -f "/root/rpmbuild/SPECS/oath-toolkit.spec" ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The oath-toolkit.spec already exists." INFO
    else
        cp oath-toolkit/oath-toolkit.spec /root/rpmbuild/SPECS
    fi

    globalcache_log "------------liboath prepare end------------" WARN
}

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
        globalcache_log "Liboath need compile" WARN
    else
        globalcache_log "Liboath has been compiled." FATAL
    fi
    globalcache_log "------------liboath compile check end------------" WARN
}

# 编译liboath
function liboath_compile()
{
    globalcache_log "------------liboath compile start------------" WARN
    compile_liboath_check
    if [ "$liboath_uncompiled" == "true" ]; then
        unset C_INCLUDE_PATH
        rpmbuild -bb /root/rpmbuild/SPECS/oath-toolkit.spec
    else
        globalcache_log "Liboath does not need to be compiled." WARN
    fi

    globalcache_log "------------liboath compile end------------" WARN
}

# 建立liboath repo源
function liboath_repo()
{
    globalcache_log "------------liboath repo start------------" WARN
    mkdir -p /home/oath
    cp -r /root/rpmbuild/RPMS/*  /home/oath/
    cd /home/oath && createrepo .

    if [ -f "/etc/yum.repos.d/local.repo" ]; then
        globalcache_log "File /etc/yum.repos.d/local.repo exists" INFO
        if cat /etc/yum.repos.d/local.repo | grep local-oath > /dev/null
        then
            globalcache_log "local-oath has been Configured" INFO
        else
            globalcache_log "local-oath need to be Configured" INFO
            echo "[local-oath]" >> /etc/yum.repos.d/local.repo
            echo "name=local-oath" >> /etc/yum.repos.d/local.repo
            echo "baseurl=file:///home/oath" >> /etc/yum.repos.d/local.repo
            echo "enabled=1" >> /etc/yum.repos.d/local.repo
            echo "gpgcheck=0" >> /etc/yum.repos.d/local.repo
            echo "priority=1" >> /etc/yum.repos.d/local.repo
        fi
    else
        globalcache_log "File /etc/yum.repos.d/local.repo does not exist" INFO
        touch /etc/yum.repos.d/local.repo
        echo "[local-oath]" >> /etc/yum.repos.d/local.repo
        echo "name=local-oath" >> /etc/yum.repos.d/local.repo
        echo "baseurl=file:///home/oath" >> /etc/yum.repos.d/local.repo
        echo "enabled=1" >> /etc/yum.repos.d/local.repo
        echo "gpgcheck=0" >> /etc/yum.repos.d/local.repo
        echo "priority=1" >> /etc/yum.repos.d/local.repo
    fi

    yum install liboath liboath-devel -y
    globalcache_log "------------liboath repo end------------" WARN
}

# 构建liboath
function compile_liboath_build()
{
    globalcache_log "------------liboath build start------------" WARN
    liboath_prepare
    liboath_compile
    liboath_repo
    globalcache_log "------------liboath build end------------" WARN
}

# 清理liboath
function compile_liboath_clean()
{
    globalcache_log "------------liboath clean start------------" WARN

    globalcache_log "rm -rf oath-toolkit" WARN
    rm -rf /root/oath-toolkit

    globalcache_log "rm -rf /home/oath" WARN
    rm -rf /home/oath

    globalcache_log "rm -rf /root/rpmbuild" WARN
    rm -rf /root/rpmbuild

    globalcache_log "rm -rf /root/.rpmmacros" WARN
    rm -rf /root/.rpmmacros
    globalcache_log "------------liboath clean end------------" WARN
}