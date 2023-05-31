#------------------------------------------------------------------------------------
# Description: 软件包分发检查
# Author: beinggod
# Create: 2023-5-19
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
set "+e"

function distribute_to_client_check()
{
    globalcache_log "------------check distribute to client start------------" WARN

    cd /home
    if [[ ! -f "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" ]];then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz not exist!" FATAL 
    fi

    if [[ ! -f "/home/apache-maven-3.6.3-bin.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-maven-3.6.3-bin.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/apache-zookeeper-3.6.3.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-zookeeper-3.6.3.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/ceph-14.2.8.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph-14.2.8.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/ceph-global-cache.patch" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph-global-cache.patch is not exist!" FATAL
    fi

    if [[ ! -f "/home/ceph-global-cache-tls.patch" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph-global-cache-tls.patch is not exist!" FATAL
    fi

    if [[ ! -f "/home/globalcache-ceph-adaptor-spec.patch" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache-ceph-adaptor-spec.patch is not exist!" FATAL
    fi

    if [[ ! -f "/home/mxml-3.2.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:mxml-3.2.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/fio-3.26.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:fio-3.26.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm is not exist!" FATAL
    fi

    if [[ ! -f "/home/boostkit-globalcache-ceph-adaptor-release-1.1.0.oe1.aarch64.rpm" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-ceph-adaptor-release-1.1.0.oe1.aarch64.rpm is not exist!" FATAL
    fi

    if [[ ! -f "/home/boostkit-zk-secure.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-zk-secure.tar.gz is not exist!" FATAL
    fi

    globalcache_log "------------check distribute to client end------------" WARN
}

function distribute_to_server_check()
{
    globalcache_log "------------check distribute packages to server start------------" WARN

    if [[ ! -d "/root/rpmbuild/RPMS/" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:/root/rpmbuild/RPMS/ is not exist!" FATAL
    fi

    if [[ ! -f "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" ]];then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz not exist!" FATAL
    fi

    if [[ ! -f "/home/apache-maven-3.6.3-bin.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-maven-3.6.3-bin.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/apache-zookeeper-3.6.3-bin.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-zookeeper-3.6.3-bin.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/apache-zookeeper-3.6.3.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-zookeeper-3.6.3.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm is not exist!" FATAL
    fi

    if [[ ! -f "/home/boostkit-zk-secure.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-zk-secure.tar.gz is not exist!" FATAL
    fi

    if [[ ! -d "/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/ is not exist!" FATAL
    fi

    if [[ ! -f "/home/cephlib-release-oe1.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:cephlib-release-oe1.tar.gz is not exist!" FATAL
    fi

    if [[ ! -f "/home/globalcache-adaptorlib-release-oe1.tar.gz" ]]; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache-adaptorlib-release-oe1.tar.gz is not exist!" FATAL
    fi

    globalcache_log "------------check distribute packagesto server end------------" WARN
}

function main()
{
cd /home
    realhostname=$(hostname)
    if [ $(echo $realhostname | grep "ceph" | wc -l) -eq 1 ]; then
        distribute_to_server_check
    fi

    realhostname=$(hostname)
    if [ $(echo $realhostname | grep "client" | wc -l) -eq 1 ]; then
        distribute_to_client_check
    fi
}
main