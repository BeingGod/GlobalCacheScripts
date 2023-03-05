#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置Global Cache软件环境
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

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

  echo "[local-oath]
name=local-oath
baseurl=file:///home/oath
enabled=1
gpgcheck=0 
priority=1" >> /etc/yum.repos.d/local.repo

  echo "[arch_fedora_online]
name=arch_fedora 
baseurl=https://repo.huaweicloud.com/fedora/releases/34/Everything/aarch64/os/
enabled=1
gpgcheck=0 
priority=2" >> /etc/yum.repos.d/openEuler.repo

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

# 安装JDK
function install_jdk()
{
  globalcache_log "------------install jdk end------------" WARN

  cd /home

  dnf install -y tar
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install tar failed!" ERROR && return 1
  
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

# 编译并安装openSSL
function compile_openSSL()
{
  globalcache_log "------------compile openSSL start------------" WARN

  cd /usr/local

  yum install net-tools expect haveged dos2unix -y
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install wget dependencies failed!" ERROR && return 1

  dnf install -y wget
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install wget failed!" ERROR && return 1

  if [ ! -f openssl-1.1.1k.tar.gz ]; then
    wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1k.tar.gz --no-check-certificate
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:download openSSL source code failed!" ERROR && return 1
  fi

  tar -zxvf openssl-1.1.1k.tar.gz
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:extract openSSL package failed!" ERROR && return 1

  cd openssl-1.1.1k
  ./config --prefix=/usr/local/ssl
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure openSSL failed!" ERROR && return 1
  make -j4
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:compile openSSL failed!" ERROR && return 1
  make install
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install openSSL failed!" ERROR && return 1

  popd

  globalcache_log "------------compile openSSL end------------" WARN
}

# 创建openSSL软连接
function create_openSSL_link()
{
  globalcache_log "------------create openSSL link start------------" WARN

  echo y | mv /usr/bin/openssl /usr/bin/openssl.bak
  echo y | mv /usr/include/openssl /usr/include/openssl.bak
  ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
  ln -s /usr/local/ssl/include/openssl /usr/include/openssl
  echo "/usr/local/ssl/lib" >> /etc/ld.so.conf 
  ldconfig -v

  globalcache_log "------------create openSSL link failed------------" WARN
}

function main()
{
  globalcache_log "------------configure Global Cache environment start------------" WARN

  create_oath_local_source
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1
  
  configure_repo
  yum clean all -y && yum makecache -y

  install_jdk
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  compile_openSSL
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  create_openSSL_link

  globalcache_log "------------configure Global Cache environment success------------" WARN
}
main