#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 控制Global Cache服务
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

function usage() 
{
    printf "Usage: gc_service_control.sh <command> \n support command: start, restart, stop, clean, init \n"
}

# bdm初始化
function bdm_init()
{
    globalcache_log "------------bdm init start------------" WARN

    cd /opt/gcache/bin
    ./gcache_startup bdm_format ../conf/bdm.conf --force
    ./gcache_startup bdm_createCapPool 4194304 200G WCachePool
    ./gcache_startup bdm_createCapPool 67108864 3500G RCachePool
    ./gcache_startup bdm_createCapPool 67108864 700G IndexPool
    ./gcache_startup bdm_df

    globalcache_log "------------bdm init end------------" WARN
}

# zookeeper清理
function zookeeper_clean()
{
    globalcache_log "------------zookeeper clean start------------" WARN

    set "+e"
    ZK_CLI_PATH="/opt/apache-zookeeper-3.6.3-bin/bin/zkCli.sh"

    echo 'deleteall /ccdb' >> ./zk_clear.txt
    echo 'deleteall /ccm_cluster' >> ./zk_clear.txt
    echo 'deleteall /pool' >> ./zk_clear.txt
    echo 'deleteall /pt_view' >> ./zk_clear.txt
    echo 'deleteall /alarm' >> ./zk_clear.txt
    echo 'deleteall /snapshot_manager' >> ./zk_clear.txt
    echo 'deleteall /ccm_clusternet_link' >> ./zk_clear.txt
    echo 'deleteall /tls' >> ./zk_clear.txt
    echo 'quit' >> ./zk_clear.txt

    cat < ./zk_clear.txt | sh ${ZK_CLI_PATH}
    echo > ./zk_clear.txt
    rm -rf ./zk_clear.txt
    set "-e"

    globalcache_log "------------zookeeper clean end------------" WARN
}

# 初始化gc服务
function start_gc_service()
{
    globalcache_log "------------Global Cache service init...------------" WARN

    systemctl stop ccm.service
    systemctl stop globalcache.service
    zookeeper_clean
    bdm_init
    systemctl daemon-reload
    echo 3 > /proc/sys/vm/drop_caches
    systemctl start ccm.service
    sleep 5
    systemctl start globalcache.service

    globalcache_log "------------Global Cache service init success!------------" WARN
}

# 停止gc服务
function stop_gc_service()
{
    globalcache_log "------------Global Cache service stop...------------" WARN

    systemctl stop ccm.service
    systemctl stop globalcache.service

    globalcache_log "------------Global Cache service stoped------------" WARN
}

# 重启gc服务
function restart_gc_service()
{
    systemctl stop ccm.service
    systemctl stop globalcache.service
    systemctl daemon-reload
    echo 3 > /proc/sys/vm/drop_caches
    systemctl start ccm.service
    sleep 5
    systemctl start globalcache.service
}

function main()
{
    local op=$1
    
    case $op in
        start)
            start_gc_service
            ;;
        restart)
            restart_gc_service
            ;;
        stop)
            stop_gc_service
            ;;
        init)
            bdm_init
            ;;
        clean)
            zookeeper_clean
            ;;
        *)
            usage
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:command not support!" ERROR && return 1
    esac
}
main $1
