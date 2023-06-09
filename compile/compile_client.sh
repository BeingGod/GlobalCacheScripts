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

# 安装mxml
function mxml_install()
{
    cd /home
    if [ ! -f "/usr/local/lib/libmxml.so" ]; then
        if [ -d "mxml-3.2" ]; then
            rm -rf mxml-3.2
        fi
        if [ -f "mxml-3.2.tar.gz" ];then
            tar -zxvf mxml-3.2.tar.gz
        else
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The mxml tar bag not exist." ERROR && return 1
        fi
        cd mxml-3.2
        ./configure
        make all
        make install
        cd ..
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The mxml has been installed." INFO
    fi
}

# 获取client源码
function client_prepare()
{
    globalcache_log "------------client prepare start------------" WARN


    if [ $(ldd --version | grep "2.33" | wc -l) -eq 1 ]; then
        # 在glibc 2.33上编译ceph，源码需要patch
        ceph_need_patch="true"
    fi

    mxml_install
    cd /home
    if [ -f "ceph-14.2.8.tar.bz2" ]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The ceph-14.2.8.tar.bz2 already exists." INFO
    else
        if [ -d "ceph-14.2.8" ]; then
            rm -rf ceph-14.2.8
        fi
        if [ -f "ceph-14.2.8.tar.gz" ]; then
            tar -zxvf ceph-14.2.8.tar.gz
        else
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The ceph-14.2.8.tar.gz not exist." ERROR
            return 1
        fi

        if [ -f "ceph-global-cache.patch" ]; then
            cp ceph-global-cache.patch ceph-14.2.8
        else
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The ceph-global-cache.patch not exist." ERROR
            return 1
        fi
        if [ -f "globalcache-ceph-adaptor-spec.patch" ]; then
            cp globalcache-ceph-adaptor-spec.patch ceph-14.2.8
        else
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The globalcache-ceph-adaptor-spec.patch not exist." ERROR
            return 1
        fi
        if [ -f "ceph-global-cache-tls.patch" ]; then
            cp ceph-global-cache-tls.patch ceph-14.2.8
        else
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The ceph-global-cache-tls.patch not exist." ERROR
            return 1
        fi

        cd ceph-14.2.8
        patch -p1 < ceph-global-cache.patch
        patch -p1 < globalcache-ceph-adaptor-spec.patch
        patch -p1 < ceph-global-cache-tls.patch
        
        set +e
        sed -i "s/^set -e/#set -e/g" install-deps.sh
        sh install-deps.sh
        set -e
        sed -i 's#%if 0%{?fedora} || 0%{?rhel}#%if 0%{?fedora} || 0%{?rhel} || 0%{?openEuler}#' ceph.spec.in

        # patch ceph
        if [ "$ceph_need_patch" == "true" ]; then
            sed -i "22i\#define HAVE_REENTRANT_STRSIGNAL //" src/global/signal_handler.h
        fi

        cd ..
        tar -cjvf ceph-14.2.8.tar.bz2 ceph-14.2.8
    fi

    if [ ! -d "/opt/gcache_adaptor_compile" ]; then
        rpm -ivh boostkit-globalcache-ceph-adaptor-release-${VERSION}.oe1.$(uname -m).rpm --force
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:The boostkit-globalcache-ceph-adaptor-release-${VERSION}.oe1.$(uname -m).rpm has been installed." INFO
    fi
    source /etc/profile

    sed -i "s/%_topdir %(echo \$HOME)\/rpmbuild/%_topdir \/home\/rpmbuild/g" /root/.rpmmacros
    rpmdev-setuptree
    for((i=1;i<6;i++)); do sed -i '$d' /root/.rpmmacros ; done
    cp ceph-14.2.8/ceph.spec /home/rpmbuild/SPECS/
    cp ceph-14.2.8.tar.bz2 /home/rpmbuild/SOURCES/
    rm -rf /etc/profile.d/performance.sh
    unset GOMP_CPU_AFFINITY

    globalcache_log "------------client prepare end------------" WARN
}

# 检查client是否已经编译过
client_uncompiled="false"
function compile_client_check()
{
    globalcache_log "------------client compile check start------------" WARN
    if [ ! -d "/home/rpmbuild/RPMS/$(uname -m)" ]; then
        client_uncompiled="true"
    fi

    if [ ! -d "/home/rpmbuild/RPMS/noarch" ]; then
        client_uncompiled="true"
    fi

    if [ "$client_uncompiled" == "true" ]; then
        globalcache_log "Client need compile." WARN
    else
        globalcache_log "Client has been compiled." FATAL 
    fi
    globalcache_log "------------client compile check end------------" WARN
}

# 安装client编译所需依赖
function client_install_dependence()
{
    if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
        sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
    fi
    
    yum install java-devel sharutils checkpolicy selinux-policy-devel gperf cryptsetup fuse-devel gperftools-devel libaio-devel libblkid-devel libcurl-devel libudev-devel libxml2-devel libuuid-devel ncurses-devel python-devel valgrind-devel xfsprogs-devel xmlstarlet yasm nss-devel libibverbs-devel openldap-devel CUnit-devel python2-Cython python3-setuptools python-prettytable lttng-ust-devel expat-devel junit boost-random keyutils-libs-devel openssl-devel libcap-ng-devel python-sphinx python2-sphinx python3-sphinx leveldb leveldb-devel snappy snappy-devel lz4 lz4-devel libbabeltrace-devel librabbitmq librabbitmq-devel librdkafka librdkafka-devel libnl3 libnl3-devel rdma-core-devel numactl numactl-devel numactl-libs createrepo openldap-devel rdma-core-devel lz4-devel expat-devel lttng-ust-devel libbabeltrace-devel python3-Cython python2-Cython gperftools-devel bc dnf-plugins-core librabbitmq-devel rpm-build java-1.8.0-openjdk-devel -y
}

# 编译client
function client_compile()
{
    globalcache_log "------------client compile start------------" WARN
    compile_client_check
    client_install_dependence
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:client install dependence failed!" ERROR && return 1
    if [ "$client_uncompiled" == "true" ]; then
        rpmbuild -bb /home/rpmbuild/SPECS/ceph.spec
    else
        globalcache_log "Client does not need to be compiled." INFO
    fi
    globalcache_log "------------client compile end------------" WARN
}

# 构建client
function compile_client_build()
{
    globalcache_log "------------client build start------------" WARN
    client_prepare
    client_compile
    globalcache_log "------------client build end------------" WARN
}

# 清理client
function compile_client_clean()
{
    globalcache_log "------------client clean start------------" WARN
    cd /home
    globalcache_log "rm -rf ceph-14.2.8" WARN
    rm -rf ceph-14.2.8

    globalcache_log "rm -rf mxml-3.2" WARN
    rm -rf mxml-3.2

    globalcache_log "rm -rf ceph-14.2.8.tar.bz2" WARN
    rm -rf ceph-14.2.8.tar.bz2

    globalcache_log "rpm -e boostkit-globalcache-ceph-adaptor-${VERSION}-1.$(uname -m)" WARN
    rpm -e boostkit-globalcache-ceph-adaptor-${VERSION}-1.$(uname -m)

    globalcache_log "rm -rf /home/rpmbuild/RPMS/*" WARN
    rm -rf /home/rpmbuild/RPMS/*

    globalcache_log "------------client clean end------------" WARN
}