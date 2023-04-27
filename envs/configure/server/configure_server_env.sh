#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置Global Cache软件环境
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

# 安装依赖
function install_dependency_packages()
{
  globalcache_log "------------install denpendency packages start------------" WARN

  yum install createrepo -y

  globalcache_log "------------install denpendency packages end------------" WARN
}

# 配置oath本地镜像
function create_oath_local_source() 
{
  globalcache_log "------------create oath local source start------------" WARN

  # 配置oath本地源
  if [ ! -f /home/oath ]; then
    mkdir -p /home/oath
  fi

  cd /home/oath
  createrepo .
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:create oath local source failed!" ERROR && return 1

  globalcache_log "------------create oath local source end------------" WARN
}

# 配置镜像仓库
function configure_repo()
{
  globalcache_log "------------configure mirror repo start------------" WARN

  if [ -f "/etc/yum.repos.d/local.repo" ]; then
    rm -f /etc/yum.repos.d/local.repo
  else
    echo "[local-oath]
name=local-oath
baseurl=file:///home/oath
enabled=1
gpgcheck=0 
priority=1" > /etc/yum.repos.d/local.repo
  fi

  if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
    rm -f /etc/yum.repos.d/fedora.repo 
  else
    echo "[arch_fedora_online]
name=arch_fedora 
baseurl=https://repo.huaweicloud.com/fedora/releases/34/Everything/aarch64/os/
enabled=1
gpgcheck=0 
priority=2" > /etc/yum.repos.d/fedora.repo
  fi

  local basearch="aarch64"

  if [ -f " /etc/yum.repos.d/ceph.repo" ]; then
    rm -f /etc/yum.repos.d/ceph.repo
  else
    echo "[Ceph] 
name=Ceph packages for $basearch 
baseurl=http://download.ceph.com/rpm-nautilus/el7/$basearch 
enabled=1 
gpgcheck=1 
type=rpm-md 
gpgkey=https://download.ceph.com/keys/release.asc 
priority=1 

[Ceph-noarch] 
name=Ceph noarch packages 
baseurl=http://download.ceph.com/rpm-nautilus/el7/noarch 
enabled=1 
gpgcheck=1 
type=rpm-md 
gpgkey=https://download.ceph.com/keys/release.asc 
priority=1 

[ceph-source] 
name=Ceph source packages 
baseurl=http://download.ceph.com/rpm-nautilus/el7/SRPMS 
enabled=1 
gpgcheck=1 
type=rpm-md 
gpgkey=https://download.ceph.com/keys/release.asc 
priority=1" > /etc/yum.repos.d/ceph.repo
  fi

  globalcache_log "------------configure mirror repo end------------" WARN
}

# 安装JDK
function install_jdk()
{
  globalcache_log "------------install jdk end------------" WARN

  cd /home

  dnf install -y tar
  
  if [ ! -d /usr/local/jdk8u282-b08 ]; then
    tar -zxvf OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz -C /usr/local/
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:extract jdk package failed!" ERROR && return 1
  fi

  echo "export JAVA_HOME=/usr/local/jdk8u282-b08" >> /etc/profile
  echo "export PATH=\${JAVA_HOME}/bin:\$PATH" >> /etc/profile

  globalcache_log "------------install jdk end------------" WARN
}

function main()
{
  globalcache_log "------------configure Global Cache environment start------------" WARN

  install_dependency_packages
  
  create_oath_local_source
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1
  
  configure_repo
  yum clean all -y && yum makecache -y

  install_jdk
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  install_sysstat
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  globalcache_log "------------configure Global Cache environment success------------" WARN
}
main