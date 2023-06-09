#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ceph软件环境 (all nodes)
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

# 安装依赖包
function install_dependencies()
{
  globalcache_log "------------install dependencies start------------" WARN

  if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
    sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
  fi

  yum install -y net-tools sysstat

  globalcache_log "------------install dependencies end------------" WARN
}

# 配置oath本地镜像
function create_oath_local_source() 
{
  globalcache_log "------------create oath local source start------------" WARN

  if [ -f "/etc/yum.repos.d/local.repo" ]; then
    rm -f /etc/yum.repos.d/local.repo
  fi

  # 禁用fedora源
  if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
    sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
  fi

  yum install createrepo -y

  cd /home/oath
  if [ ! -d "/home/oath/repodata" ]; then
    createrepo .
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:create oath local source failed!" ERROR && return 1
  fi
  
  echo "[local-oath]
name=local-oath
baseurl=file:///home/oath
enabled=1
gpgcheck=0 
priority=1" > /etc/yum.repos.d/local.repo

  if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
    rm -f /etc/yum.repos.d/fedora.repo 
  fi

  echo "[arch_fedora_online]
name=arch_fedora 
baseurl=https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/34/Everything/aarch64/os/
enabled=1
gpgcheck=0 
priority=2" > /etc/yum.repos.d/fedora.repo

  globalcache_log "------------create oath local source end------------" WARN
}

# 安装compat-openssl包
function install_compat_openssl()
{
  globalcache_log "------------install compat-openssl start------------" WARN

  cd /home

  # 判断是否安装了compat-openssl
  if [ $(yum list installed | grep "compat-openssl10.aarch64" | wc -l) -eq 0 ]; then
    if [ ! -f "compat-openssl10-1.0.2o-5.fc30.aarch64.rpm" ]; then
      wget https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/30/Everything/aarch64/os/Packages/c/compat-openssl10-1.0.2o-5.fc30.aarch64.rpm --no-check-certificate
      [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:download compat-openssl package failed!" ERROR && return 1
    else
      globalcache_log "The compat-openssl10-1.0.2o-5.fc30.aarch64.rpm is already exist." INFO
    fi
    
    rpm -ivh compat-openssl10-1.0.2o-5.fc30.aarch64.rpm
  else
    globalcache_log "The compat-openssl already installed." INFO
  fi

  globalcache_log "------------install compat-openssl end------------" WARN

  return 0
}

# 设置linux安全模式
function configure_permissive_mode()
{
  globalcache_log "------------configure permissive mode start------------" WARN

  if [[ $(cat /etc/selinux/config | grep "SELINUX=enforcing" | wc -l) -eq 1 ]]; then
    setenforce permissive
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure permissive mode failed!" ERROR && return 1

    sed -i 's#SELINUX=enforcing#SELINUX=permissive#g' /etc/selinux/config
  else
    globalcache_log "------------Linux is already in permissive mode------------" INFO
  fi

  globalcache_log "------------configure permissive mode end------------" WARN
}

# 配置镜像仓库
function configure_ceph_repo()
{
  globalcache_log "------------configure mirror repo start------------" WARN

  local basearch="aarch64"

  if [ -f " /etc/yum.repos.d/ceph.repo" ]; then
    rm -f /etc/yum.repos.d/ceph.repo
  fi

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

  globalcache_log "------------configure mirror repo end------------" WARN
}

# 安装ceph
function install_ceph()
{
  globalcache_log "------------install ceph start------------" WARN

  if [ $(cat "/etc/yum.conf" | grep -oe "sslverify=false" | wc -l) -eq 0 ]; then
    echo "sslverify=false" >> /etc/yum.conf # 设置yum证书验证状态
  fi

  if [ $(cat "/etc/yum.conf" | grep -oe "deltarpm=0" | wc -l) -eq 0 ]; then
    echo "deltarpm=0" >> /etc/yum.conf # 设置yum证书验证状态
  fi

  dnf -y install librados2-14.2.8 ceph-14.2.8

  pip install prettytable werkzeug

  ceph -v

  globalcache_log "------------install ceph end------------" WARN
}

function main()
{
  install_dependencies

  configure_ceph_repo
  
  create_oath_local_source

  # 安装compat-openssl
  install_compat_openssl
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  # 设置linux安全模式
  configure_permissive_mode
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  # 安装ceph
  install_ceph
}
main