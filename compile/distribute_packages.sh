#------------------------------------------------------------------------------------
# Description: 分发软件包
# Author: beinggod
# Create: 2023-3-28
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
set "-e"

# 设置pdsh组
function configure_pdsh_group()
{
  globalcache_log "------------configure pdsh group start------------" WARN

  if [ ! -d "/etc/dsh/group" ]; then
    mkdir -p /etc/dsh/group
  else
    globalcache_log "The /etc/dsh/group is already exist." INFO
  fi

  cat /home/hostnamelist.txt | grep -E -oe "ceph1" > /etc/dsh/group/ceph1                                  # ceph1
  cat /home/hostnamelist.txt | grep -E -oe "ceph[0-9]*" > /etc/dsh/group/ceph                              # all ceph
  cat /home/hostnamelist.txt | grep -E -oe "client[0-9]*" > /etc/dsh/group/client                          # all client
  cat /home/hostnamelist.txt | grep -E -oe "(ceph[0-9]*)|(client[0-9]*)" > /etc/dsh/group/all              # all

  globalcache_log "------------configure pdsh group end------------" WARN
}

function distribute_to_client()
{
     cd /home
    if [[ -f "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" ]];then
        pdcp -g client  "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz not exist!" ERROR && return 1
    fi

    if [[ -f "/home/apache-maven-3.6.3-bin.tar.gz" ]]; then
        pdcp -g client  "/home/apache-maven-3.6.3-bin.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-maven-3.6.3-bin.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/apache-zookeeper-3.6.3.tar.gz" ]]; then
        pdcp -g client "/home/apache-zookeeper-3.6.3.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-zookeeper-3.6.3.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/ceph-14.2.8.tar.gz" ]]; then
        pdcp -g client "/home/ceph-14.2.8.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph-14.2.8.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/ceph-global-cache-tls.patch" ]]; then
        pdcp -g client "/home/ceph-global-cache-tls.patch" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:ceph-global-cache-tls.patch is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/globalcache-ceph-adaptor-spec.patch" ]]; then
        pdcp -g client "/home/aglobalcache-ceph-adaptor-spec.patch" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache-ceph-adaptor-spec.patch is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/mxml-3.2.tar.gz" ]]; then
        pdcp -g client "/home/mxml-3.2.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:mxml-3.2.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/fio-3.26.tar.gz" ]]; then
        pdcp -g client "/home/fio-3.26.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:fio-3.26.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm" ]]; then
        pdcp -g client "/home/boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/boostkit-globalcache-ceph-adaptor-release-1.1.0.oe1.aarch64.rpm" ]]; then
        pdcp -g client "/home/boostkit-globalcache-ceph-adaptor-release-1.1.0.oe1.aarch64.rpm" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-ceph-adaptor-release-1.1.0.oe1.aarch64.rpm is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/boostkit-zk-secure.tar.gz" ]]; then
        pdcp -g client "/home/boostkit-zk-secure.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-zk-secure.tar.gz is not exist!" ERROR && return 1
    fi
}

function distribute_to_server()
{
    globalcache_log "------------distribute packages to server start------------" WARN

    cd /home
    if [[ -f "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" ]];then
        pdcp -g ceph -X ceph1 "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz not exist!" ERROR && return 1
    fi

    if [[ -f "/home/apache-maven-3.6.3-bin.tar.gz" ]]; then
        pdcp -g ceph -X ceph1 "/home/apache-maven-3.6.3-bin.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-maven-3.6.3-bin.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/apache-zookeeper-3.6.3.tar.gz" ]]; then
        pdcp -g ceph -X ceph1 "/home/apache-zookeeper-3.6.3.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:apache-zookeeper-3.6.3.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm" ]]; then
        pdcp -g ceph -X ceph1 "/home/boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-globalcache-release-1.1.0.oe1.aarch64.rpm is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/boostkit-zk-secure.tar.gz" ]]; then
        pdcp -g ceph -X ceph1 "/home/boostkit-zk-secure.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:boostkit-zk-secure.tar.gz is not exist!" ERROR && return 1
    fi

    pdsh -R ssh -g ceph -X ceph1 "mkdir -p /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/"
    if [[ -d "/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/" ]]; then
        pdcp -r -g ceph -X ceph1 "/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/" "/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:/home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/ is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/cephlib-release-oe1.tar.gz" ]]; then
        pdcp -g ceph -X ceph1 "/home/cephlib-release-oe1.tar.gz" "/home/cephlib-release-oe1.tar.gz"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:cephlib-release-oe1.tar.gz is not exist!" ERROR && return 1
    fi

    if [[ -f "/home/globalcache-adaptorlib-release-oe1.tar.gz" ]]; then
        pdcp -g ceph -X ceph1 "/home/cephlib-release-oe1.tar.gz" "/home"
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:globalcache-adaptorlib-release-oe1.tar.gz is not exist!" ERROR && return 1
    fi

    globalcache_log "------------distribute packagesto server end------------" WARN
}

function main()
{
    configure_pdsh_group

    distribute_to_server
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:distribute packages to server nodes failed!" ERROR && return 1

    distribute_to_client
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:distribute packages to client nodes failed!" ERROR && return 1
}
main