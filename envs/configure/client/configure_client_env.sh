#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置Global Cache软件环境
# Author: beinggod
# Create: 2023-2-25
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

# 设置shell启动进程所占用资源
function configure_profile()
{
  globalcache_log "------------configure /etc/profile start------------" WARN


  echo "ulimit -n 524288" >> /etc/profile
  source /etc/profile

  globalcache_log "------------configure /etc/profile end------------" WARN

}

# 安装依赖
function install_dependency_packages()
{
  globalcache_log "------------install denpendency packages start------------" WARN

  yum install gtk-doc pam-devel rpmdevtools xmlsec1-devel \
              libtool-ltdl-devel createrepo openldap-devel \
              rdma-core-devel lz4-devel expat-devel lttng-ust-devel \
              libbabeltrace-devel python3-Cython python2-Cython \
              gperftools-devel bc dnf-plugins-core librabbitmq-devel \
              leveldb leveldb-devel numactl numactl-devel rpmdevtools \
              rpm-build libtool python-pip python3-pip librbd-devel \
              git -y
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install dependency packages failed!" ERROR && return 1

  globalcache_log "------------install denpendency packages end------------" WARN
}

# 创建Ceph和oath的本地源
function create_local_source()
{
  globalcache_log "------------create local source start------------" WARN

  if [ ! -d /home/rpm ]; then
    mkdir -p /home/rpm
  fi

  cd /home/rpm
  createrepo .
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:create ceph local source failed!" ERROR && return 1

  if [ ! -d /home/oath ]; then
    mkdir -p /home/oath
  fi

  cd /home/oath
  createrepo .
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:create oath local source failed!" ERROR && return 1

  globalcache_log "------------create local source end------------" WARN
} 

# 配置镜像仓库
function configure_repo()
{
  globalcache_log "------------configure mirror repo start------------" WARN

  if [ ! -f /etc/yum.repos.d/local.repo ]; then
    touch /etc/yum.repos.d/local.repo
  fi
  
  echo "[local]
name=local
baseurl=file:///home/rpm
enabled=1
gpgcheck=0
priority=1

[local-oath]
name=local-oath
baseurl=file:///home/oath
enabled=1
gpgcheck=0
priority=1" >> /etc/yum.repos.d/local.repo

  globalcache_log "------------configure mirror repo start------------" WARN
}

# 安装JDK
function install_jdk()
{
  globalcache_log "------------install jdk end------------" WARN

  cd /home
  # dnf install -y tar
  # [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install tar failed!" ERROR && return 1
  
  if [ ! -d /usr/local/jdk8u282-b08 ]; then
    tar -zxvf OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz -C /usr/local/
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:extract jdk package failed!" ERROR && return 1
  fi

  echo "export JAVA_HOME=/usr/local/jdk8u282-b08" >> /etc/profile
  echo "export PATH=\$\{JAVA_HOME}/bin:\$PATH" >> /etc/profile

  source /etc/profile

  java -version
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install jdk failed!" ERROR && return 1

  globalcache_log "------------install jdk end------------" WARN
}

function main()
{
  cd /home

  configure_profile

  install_dependency_packages
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  create_local_source
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  configure_repo
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  install_jdk
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1
}
main