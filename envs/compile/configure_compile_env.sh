#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置编译节点环境
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

function configure_compile()
{
    globalcache_log "------------Configure compile node environment start------------" WARN

    cd /home

    # 设置yum证书验证状态为不验证
    echo -e 'sslverify=false\ndeltarpm=0' >> /etc/yum.conf

    # 配置pip华为代理
    if [ ! -d "~/.pip" ] ; then
      mkdir -p ~/.pip
    fi

    # 禁用fedora源
    if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
      sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
    fi

    if [ $(cat ~/.pip/pip.conf | grep -oe "repo.huaweicloud.com" | wc -l) -ne 2 ]; then 
      echo -e '[global]\ntimeout = 120\nindex-url = https://repo.huaweicloud.com/repository/pypi/simple\ntrusted-host = repo.huaweicloud.com' >> ~/.pip/pip.conf
    fi

    yum clean all

    java -version
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure java failed!" ERROR && return 1

    mvn -v
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure maven failed!" ERROR && return 1

    globalcache_log "------------Configure compile node environment end------------" WARN
}

# 安装JDK
function install_jdk()
{
  globalcache_log "------------install jdk start------------" WARN

  cd /home

  if [ ! -d "/usr/local/jdk8u282-b08" ]; then
    tar -zxvf OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz -C /usr/local/
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:extract jdk package failed!" ERROR && return 1
  fi

  if [ $(cat "/etc/profile" | grep -oe "export JAVA_HOME=/usr/local/jdk8u282-b08" | wc -l ) -eq 0 ]; then
    echo "export JAVA_HOME=/usr/local/jdk8u282-b08" >> /etc/profile
  fi

  if [ $(cat "/etc/profile" | grep -oe "export PATH=\${JAVA_HOME}/bin:\$PATH" | wc -l ) -eq 0 ]; then
    echo "export PATH=\${JAVA_HOME}/bin:\$PATH" >> /etc/profile
  fi

  source /etc/profile

  java -version
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install jdk failed!" ERROR && return 1

  globalcache_log "------------install jdk end------------" WARN
}

# 安装maven
function install_maven()
{
  globalcache_log "------------install maven start------------" WARN

  cd /home

  if [ ! -d "/usr/local/apache-maven-3.6.3" ]; then
    tar -zxvf apache-maven-3.6.3-bin.tar.gz -C /usr/local/
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:extract maven package failed!" ERROR && return 1
  fi

  if [ $(cat "/etc/profile" | grep -oe "export MAVEN_HOME=/usr/local/apache-maven-3.6.3" | wc -l ) -eq 0 ]; then
    echo "export MAVEN_HOME=/usr/local/apache-maven-3.6.3" >> /etc/profile
  fi

  if [ $(cat "/etc/profile" | grep -oe "export PATH=\${PATH}:\${MAVEN_HOME}/bin" | wc -l ) -eq 0 ]; then
    echo "export PATH=\${PATH}:\${MAVEN_HOME}/bin" >> /etc/profile
  fi
  
  source /etc/profile

  mvn -v
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install maven failed!" ERROR && return 1

  globalcache_log "------------install maven end------------" WARN
}

function main()
{
  install_jdk
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure compile environment failed!" ERROR && return 1

  install_maven
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure compile environment failed!" ERROR && return 1

  configure_compile
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure compile environment failed!" ERROR && return 1

}
main