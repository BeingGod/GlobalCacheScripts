#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置Global Cache软件环境
# Author: beinggod
# Create: 2023-2-25
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# 设置shell启动进程所占用资源
function configure_profile()
{
  globalcache_log "------------configure /etc/profile start------------" WARN

  if [ $(cat "/etc/profile" | grep -oe "ulimit -n 524288" | wc -l ) -eq 0 ];then
    echo "ulimit -n 524288" >> /etc/profile
    source /etc/profile
  fi

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

  globalcache_log "------------install denpendency packages end------------" WARN
}

# 创建Ceph和oath的本地源
function create_local_source()
{
  globalcache_log "------------create local source start------------" WARN

  if [ ! -d /home/rpm ]; then
    mkdir -p /home/rpm
  fi

  # copy compiled RPMS
  cp -r /home/rpmbuild/RPMS/* /home/rpm

  cd /home/rpm
  createrepo .
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:create ceph local source failed!" ERROR && return 1

  if [ ! -d "/home/oath" ]; then
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

  if [ $(cat "/etc/yum.repos.d/local.repo" | grep "[local]" | wc -l) -eq 0]; then
  echo "[local]
name=local
baseurl=file:///home/rpm
enabled=1
gpgcheck=0
priority=1" >> /etc/yum.repos.d/local.repo
  fi

  globalcache_log "------------configure mirror repo start------------" WARN
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
}
main