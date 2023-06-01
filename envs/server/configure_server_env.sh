#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置Global Cache软件环境
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"


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

  if [ $(cat "/etc/profile" | grep -oe "export JAVA_HOME=/usr/local/jdk8u282-b08" | wc -l ) -eq 0 ]; then
    echo "export JAVA_HOME=/usr/local/jdk8u282-b08" >> /etc/profile
  fi

  if [ $(cat "/etc/profile" | grep -oe "export PATH=\${JAVA_HOME}/bin:\$PATH" | wc -l ) -eq 0 ]; then
    echo "export PATH=\${JAVA_HOME}/bin:\$PATH" >> /etc/profile
  fi

  globalcache_log "------------install jdk end------------" WARN
}


# 编译并安装openSSL
function install_openssl()
{
  globalcache_log "------------compile openSSL start------------" WARN

  cd /usr/local

  yum install net-tools expect haveged dos2unix -y

  dnf install -y wget

  if [ ! -d "/usr/local/ssl" ]; then
    if [ ! -f openssl-1.1.1n.tar.gz ]; then
      wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1n.tar.gz --no-check-certificate
      [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:download openSSL source code failed!" ERROR && return 1
    fi

    tar -zxvf openssl-1.1.1n.tar.gz

    cd openssl-1.1.1n
    ./config --prefix=/usr/local/ssl
    make -j
    make install
  else
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:openSSL already installed!" WARN && return 0 
  fi

  if [ -f "/usr/bin/openssl" ]; then
    echo y | mv /usr/bin/openssl /usr/bin/openssl.bak
  fi

  if [ -d "/usr/include/openssl" ]; then
    echo y | mv /usr/include/openssl /usr/include/openssl.bak
  fi

  ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
  ln -s /usr/local/ssl/include/openssl /usr/include/openssl

  globalcache_log "------------compile openSSL end------------" WARN
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

  install_openssl  
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  install_sysstat
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure Global Cache environment failed!" ERROR && return 1

  globalcache_log "------------configure Global Cache environment success------------" WARN
}
main