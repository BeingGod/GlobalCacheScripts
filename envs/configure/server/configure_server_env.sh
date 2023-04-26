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
    rm -f /etc/yum.repos.d/openEuler.repo
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

# 编译并安装openSSL
function compile_openSSL()
{
  globalcache_log "------------compile openSSL start------------" WARN

  cd /usr/local

  yum install net-tools expect haveged dos2unix -y

  dnf install -y wget

  if [ ! -d "/usr/local/ssl" ]; then
    if [ ! -f openssl-1.1.1k.tar.gz ]; then
      wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1k.tar.gz --no-check-certificate
      [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:download openSSL source code failed!" ERROR && return 1
    fi

    tar -zxvf openssl-1.1.1k.tar.gz

    cd openssl-1.1.1k
    ./config --prefix=/usr/local/ssl
    make -j
    make install
  else
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:openSSL already installed!" WARN && return 0 
  fi

  globalcache_log "------------compile openSSL end------------" WARN
}

# 创建openSSL软连接
function create_openSSL_link()
{
  globalcache_log "------------create openSSL link start------------" WARN

  if [ -f "/usr/bin/openssl" ]; then
    echo y | mv /usr/bin/openssl /usr/bin/openssl.bak
  fi

  if [ -d "/usr/include/openssl" ]; then
    echo y | mv /usr/include/openssl /usr/include/openssl.bak
  fi
  
  ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
  ln -s /usr/local/ssl/include/openssl /usr/include/openssl
  echo "/usr/local/ssl/lib" >> /etc/ld.so.conf 
  ldconfig -v

  globalcache_log "------------create openSSL link failed------------" WARN
}

function install_sysstat()
{
  globalcache_log "------------install sysstat start------------" WARN

  yum install sysstat  -y

  globalcache_log "------------install sysstat end------------" WARN
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

  compile_openSSL
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  create_openSSL_link

  install_sysstat
   [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  globalcache_log "------------configure Global Cache environment success------------" WARN
}
main