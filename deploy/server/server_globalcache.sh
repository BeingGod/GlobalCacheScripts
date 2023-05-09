#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install server script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
GLOBALCACHEOP_PWD=globalcacheop
source $SCRIPT_HOME/../../common/log.sh


# globalcache安装
function globalcache_install()
{
    globalcache_log "------------globalcache install start------------" WARN

    cd /home
    if id -u globalcache >/dev/null 2>&1; then
        echo "user globalcache exists"
    else
        echo "user globalcache does not exist"
        groupadd globalcache
        useradd -g globalcache -s /sbin/nologin globalcache
    fi

    if id -u ccm >/dev/null 2>&1; then
        echo "user ccm exists"
    else
        echo "user ccm does not exist"
        useradd -g globalcache -s /sbin/nologin ccm
    fi

    if [ -f "boostkit-globalcache-release-${VERSION}.oe1.aarch64.rpm" ]; then
        rpm -ivh boostkit-globalcache-release-${VERSION}.oe1.aarch64.rpm --force
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-release-${VERSION}.oe1.aarch64.rpm not exist." ERROR
        return 1
    fi
    
    if [ -f "cephlib-release-oe1.tar.gz" ]; then
        tar zxvf cephlib-release-oe1.tar.gz
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:cephlib-release-oe1.tar.gz not exist." ERROR
        return 1
    fi
    mv cephlib/* /opt/gcache/lib/

    chmod 550  /opt/gcache/lib/*
    chown globalcache:globalcache -R /opt/gcache/lib/

    # 添加运维用户
    if id -u globalcacheop >/dev/null 2>&1; then
        echo "user globalcacheop exists"
    else
        echo "user globalcacheop does not exist"
        echo "adding globalcachep, password is $globalcacheop_passwd"
        
        useradd -p $(openssl passwd -1 $GLOBALCACHEOP_PWD) -g globalcache -s /bin/bash globalcacheop
        usermod -a -G systemd-journal globalcache

        echo "globalcacheop ALL=(root) /usr/bin/systemctl start ccm" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl stop ccm" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl status ccm" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl start" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl stop" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl status" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl start GlobalCache.target" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl stop GlobalCache.target" >> /etc/sudoers
        echo "globalcacheop ALL=(root) /usr/bin/systemctl status GlobalCache.target" >> /etc/sudoers
    fi

    chmod 777 $SCRIPT_HOME/../../data

    globalcache_log "------------globalcache install end------------" WARN
}

# 开源代码安装
function opensource_install()
{
    globalcache_log "------------opensource install start------------" WARN

    cd /home
    if [ -f "globalcache-adaptorlib-release-oe1.tar.gz" ]; then
        tar -zxvf globalcache-adaptorlib-release-oe1.tar.gz
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache-adaptorlib-release-oe1.tar.gz not exist." ERROR
        return 1
    fi
    cd globalcache-adaptorlib
    \cp lib* /opt/gcache/lib
    chown globalcache:globalcache /opt/gcache/lib/libosa.so
    chown globalcache:globalcache /opt/gcache/lib/libproxy.so

    globalcache_log "------------opensource install end------------" WARN
}

# config_scm_init初始化
function config_scm_init()
{
    globalcache_log "------------config_scm init start------------" WARN

    cd /opt/gcache/conf/

    realhostname=$(hostname)
    node_num=$(awk '{print NR}' /home/nodelist.txt | tail -n1)
    vnode_num=$(($node_num*4))
    zk_server_num=$(cat /home/nodelist.txt |awk '{ print $11}'| grep 1 |wc -l)
    sed -i "s/^zk_server_list = .*/zk_server_list = /g" config_scm.conf
    count=1

    cat /home/nodelist.txt | awk '{print $0}' | while read line
    do
    hostname=$(echo $line | awk '{ print $1}')
    if [[ "$hostname" == "$realhostname" ]]; then
        local_ipv4_addr=$(echo $line | awk '{ print $4}')
        public_ipv4_addr=$(echo $line | awk '{ print $5}')
        cluster_ipv4_addr=$(echo $line | awk '{ print $6}')
        pt_num=$(echo $line | awk '{ print $7}')
        pg_num=$(echo $line | awk '{ print $8}')
        ccm_monitor=$(echo $line | awk '{ print $12}')
        sed -i "s/^local_ipv4_addr = .*/local_ipv4_addr = $local_ipv4_addr/g" config_scm.conf
        sed -i "s/^public_ipv4_addr = .*/public_ipv4_addr = $public_ipv4_addr/g" config_scm.conf
        sed -i "s/^cluster_ipv4_addr = .*/cluster_ipv4_addr = $cluster_ipv4_addr/g" config_scm.conf
        sed -i "s/^pt_num = .*/pt_num = $pt_num/g" config_scm.conf
        sed -i "s/^pg_num = .*/pg_num = $pg_num/g" config_scm.conf
        sed -i "s/^ccm_monitor = .*/ccm_monitor = $ccm_monitor/g" config_scm.conf
    fi

    zk_server_on=$(echo $line | awk '{ print $11}')
    if [ $zk_server_on -eq 1 ];then
        if (( $count != $zk_server_num )); then
            sed -i "s/^zk_server_list = .*/&$hostname:2181,/" config_scm.conf
            count=$(($count+1))
        else
            sed -i "s/^zk_server_list = .*/&$hostname:2181/" config_scm.conf
        fi
    fi
    done

    sed -i "s/^zk_tls_on = .*/zk_tls_on = 0/g" config_scm.conf
    sed -i "s/^cache_node_num = .*/cache_node_num = $node_num/g" config_scm.conf
    sed -i "s/^vnode_num = .*/vnode_num = $vnode_num/g" config_scm.conf

    if (( $node_num <= 3 )); then
        sed -i "s/^replication_num = .*/replication_num = $node_num/g" config_scm.conf
    else
        sed -i "s/^replication_num = .*/replication_num = 3/g" config_scm.conf
    fi
    

    cat config_scm.conf

    globalcache_log "------------config_scm init end------------" WARN
}

# config_sa_init初始化
function config_sa_init()
{
    globalcache_log "------------config_sa init start------------" WARN

    cd /opt/gcache/conf/

    realhostname=$(hostname)

    cat /home/nodelist.txt | awk '{print $0}' | while read line
    do
    hostname=$(echo $line | awk '{ print $1}')
    if [[ "$hostname" == "$realhostname" ]]; then
        listen_ip=$(echo $line | awk '{ print $4}')
        sed -i "s/^listen_ip=.*/listen_ip=$listen_ip/g" config_sa.conf
    fi
    done

    cat config_sa.conf

    globalcache_log "------------config_sa init end------------" WARN
}

# gcache_xml_init初始化
function gcache_xml_init()
{
    globalcache_log "------------gcache.xml init start------------" WARN

    cd /opt/gcache/conf/
    sed -i "s/tls_status>on/tls_status>off/g" gcache.xml
    cat /home/nodelist.txt | awk '{print $0}' | while read line
    do
    hostname=$(echo $line | awk '{ print $1}')
    if [[ "$hostname" == $(hostname) ]]; then
        local_ipv4_addr=$(echo $line | awk '{ print $4}')
        sed -i "s/<ccm_address>0.0.0.0:7910/<ccm_address>$local_ipv4_addr:7910/g" gcache.xml
        sed -i "s/<gc_address>0.0.0.0:7915/<gc_address>$local_ipv4_addr:7915/g" gcache.xml
    fi
    done

    globalcache_log "------------gcache.xml init end------------" WARN
}

# bdm_conf_init初始化
function bdm_conf_init()
{
    globalcache_log "------------bdm.conf init start------------" WARN

    cd /opt/gcache/conf/

    realhostname=$(hostname)

    cat /home/nodelist.txt | awk '{print $0}' | while read line
    do
    hostname=$(echo $line | awk '{ print $1}')
    if [[ "$hostname" == "$realhostname" ]]; then
        device1=$(echo $line | awk '{ print $9}')
        device2=$(echo $line | awk '{ print $10}')
        sed -i "s/^device:id:0:sn:0:size:0:status:0:name:.*/device:id:0:sn:0:size:0:status:0:name:\/dev\/$device1/g" bdm.conf
        sed -i "s/^device:id:1:sn:0:size:0:status:0:name:.*/device:id:1:sn:0:size:0:status:0:name:\/dev\/$device2/g" bdm.conf
    fi
    done

    globalcache_log "------------bdm.conf init end------------" WARN
}

function set_max_map_count()
{
    if [[ "$(cat /etc/sysctl.conf | grep "vm.max_map_count = 1000000")" = "" ]]
    then
        echo "vm.max_map_count = 1000000" >> /etc/sysctl.conf
        sysctl -p
    fi
}

# 安裝server
function server_globalcache_install()
{
    globalcache_log "------------server globalcache install start------------" WARN

    globalcache_install
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache install failed!" ERROR && return 1
    opensource_install
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:opensource install failed!" ERROR && return 1
    config_scm_init
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:config scm init failed!" ERROR && return 1
    config_sa_init
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:config sa init failed!" ERROR && return 1
    gcache_xml_init
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:gcache xml init failed!" ERROR && return 1
    bdm_conf_init
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:config bdm init failed!" ERROR && return 1
    set_max_map_count
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:set vm.max_map_count failed!" ERROR && return 1

    globalcache_log "------------server globalcache install end------------" WARN
}

# 检查server
function server_globalcache_check()
{
    globalcache_log "------------server globalcache check start------------" WARN

    systemctl status globalcache.service

    globalcache_log "------------server globalcache check end------------" WARN
}

# 卸载server
function server_globalcache_uninstall()
{
    globalcache_log "------------server globalcache uninstall start------------" WARN

    systemctl stop GlobalCache.target
    rpm -e boostkit-globalcache
    rm -rf /opt/gcache

    globalcache_log "------------server globalcache uninstall end------------" WARN
}
