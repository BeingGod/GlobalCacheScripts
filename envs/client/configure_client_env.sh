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
set "+e"

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

  if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
    sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
  fi

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


function main()
{
  cd /home

  configure_profile

  install_dependency_packages
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1
}
main