#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install server script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

# zookeeper config
function zookeeper_config()
{
    globalcache_log "------------zookeeper config start------------" WARN

    cd /opt/apache-zookeeper-3.6.3-bin/
    if [ ! -d "zkData" ]; then
        mkdir zkData
    fi

    cd /opt/apache-zookeeper-3.6.3-bin/conf
    mv zoo_sample.cfg zoo.cfg

    realhostname=$(hostname)
    cat /home/nodelist.txt | awk '{print $0}' | while read line
    do
        hostname=$(echo $line | awk '{ print $1}')
        nodeid=$(echo $line | awk '{ print $2}')
        zk_server_on=$(echo $line | awk '{ print $11}')

        if [[ "$hostname" == "$realhostname" ]]; then
            echo $nodeid > /opt/apache-zookeeper-3.6.3-bin/zkData/myid
        fi

        sed -i "/^server.${nodeid}.*/d" /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
        if [ $zk_server_on -eq 1 ];then
            echo server.${nodeid}=$hostname:2888:3888 >> /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
        fi
    done

    sed -i "s/tickTime=.*/tickTime=1000/g" /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i "s/initLimit=.*/initLimit=10/g" /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i "s/syncLimit=.*/syncLimit=2/g" /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i "s/dataDir=.*/dataDir=\/opt\/apache-zookeeper-3.6.3-bin\/zkData/g" /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg

    sed -i '/^autopurge.purgeInterval=.*/d' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i '$a autopurge.purgeInterval=3' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    
    sed -i '/^autopurge.snapRetainCount=.*/d' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i '$a autopurge.snapRetainCount=3' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg

    zk_server_num=$(cat /home/nodelist.txt |awk '{ print $11}'| grep 1 |wc -l)
    zk_max_connect=$(expr 1000 / $zk_server_num)
    sed -i '/^maxClientCnxns=.*/d' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i "\$a maxClientCnxns=$zk_max_connect" /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg

    sed -i '/^4lw.commands.whitelist=.*/d' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg
    sed -i '$a 4lw.commands.whitelist=*' /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg

    cat /opt/apache-zookeeper-3.6.3-bin/zkData/myid
    cat /opt/apache-zookeeper-3.6.3-bin/conf/zoo.cfg

    globalcache_log "------------zookeeper config end------------" WARN
}

# zookeeper service文件
function zookeeper_service()
{
    globalcache_log "------------zookeeper service start------------" WARN

    if [ -f "/etc/rc.d/init.d/zookeeper" ]; then
        echo "File /etc/rc.d/init.d/zookeeper exists"
    else
        cd /etc/rc.d/init.d/
        touch zookeeper
        chmod +x zookeeper
        echo '#!/bin/bash' >> zookeeper
        echo '#chkconfig:2345 20 90' >> zookeeper
        echo '#description:zookeeper' >> zookeeper
        echo '#processname:zookeeper' >> zookeeper
        echo 'export JAVA_HOME=/usr/local/jdk8u282-b08' >> zookeeper
        echo 'case $1 in' >> zookeeper
        echo 'start) su root /opt/apache-zookeeper-3.6.3-bin/bin/zkServer.sh start;;' >> zookeeper
        echo 'stop) su root /opt/apache-zookeeper-3.6.3-bin/bin/zkServer.sh stop;;' >> zookeeper
        echo 'status) su root /opt/apache-zookeeper-3.6.3-bin/bin/zkServer.sh status;;' >> zookeeper
        echo 'restart) su root /opt/apache-zookeeper-3.6.3-bin/bin/zkServer.sh restart;;' >> zookeeper
        echo '*) echo "require start|stop|status|restart" ;;' >> zookeeper
        echo 'esac' >> zookeeper
    fi

    set +e
    kill -9 $(ps -ef |grep zookeeper |awk '{print $2}')
    service zookeeper restart
    # systemctl start zookeeper 

    chkconfig --add zookeeper

    globalcache_log "------------zookeeper service end------------" WARN
}

# 安装zookeeper
function server_zookeeper_install()
{
    globalcache_log "------------install server zookeeper start------------" WARN

    \cp /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/include/zookeeper/* /usr/include
    \cp /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/lib/* /usr/lib64
    if [ -f "apache-zookeeper-3.6.3-bin.tar.gz" ]; then
        tar -zxvf apache-zookeeper-3.6.3-bin.tar.gz -C /opt
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-zookeeper-3.6.3-bin.tar.gz not exist." ERROR
        return 1
    fi

    zookeeper_config
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:zookeeper config failed!" ERROR && return 1
    zookeeper_service
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:server zookeeper failed!" ERROR && return 1

    globalcache_log "------------install server zookeeper end------------" WARN
}

# 删除zookeeper头文件
function server_zookeeper_include_uninstall()
{
    globalcache_log "------------uninstall server zookeeper include start------------" WARN

    echo "rm -rf /usr/include/proto.h"
    rm -rf /usr/include/proto.h
    echo "rm -rf /usr/include/recordio.h"
    rm -rf /usr/include/recordio.h
    echo "rm -rf /usr/include/zookeeper.h"
    rm -rf /usr/include/zookeeper.h
    echo "rm -rf /usr/include/zookeeper.jute.h"
    rm -rf /usr/include/zookeeper.jute.h
    echo "rm -rf /usr/include/zookeeper_log.h"
    rm -rf /usr/include/zookeeper_log.h
    echo "rm -rf /usr/includezookeeper_version.h"
    rm -rf /usr/include/zookeeper_version.h

    globalcache_log "------------uninstall server zookeeper include end------------" WARN
}

# 删除zookeeper库文件
function server_zookeeper_lib_uninstall()
{
    globalcache_log "------------uninstall server zookeeper lib start------------" WARN

    echo "rm -rf /usr/lib64/libzookeeper_*"
    rm -rf /usr/lib64/libzookeeper_*

    globalcache_log "------------uninstall server zookeeper lib end------------" WARN
}

# 删除zookeeper可执行文件
function server_zookeeper_bin_uninstall()
{
    globalcache_log "------------uninstall server zookeeper bin start------------" WARN

    echo "rm -rf /opt/apache-zookeeper-3.6.3-bin"
    rm -rf /opt/apache-zookeeper-3.6.3-bin

    globalcache_log "------------uninstall server zookeeper bin end------------" WARN
}

# 卸载zookeeper
function server_zookeeper_uninstall()
{
    globalcache_log "------------uninstall server zookeeper start------------" WARN

    server_zookeeper_include_uninstall
    server_zookeeper_lib_uninstall
    server_zookeeper_bin_uninstall
    rm -rf /etc/rc.d/init.d/zookeeper

    globalcache_log "------------uninstall server zookeeper end------------" WARN
}