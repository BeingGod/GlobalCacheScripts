#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置编译节点环境
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

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

    echo -e '[global]\ntimeout = 120\nindex-url = https://repo.huaweicloud.com/repository/pypi/simple\ntrusted-host = repo.huaweicloud.com' >> ~/.pip/pip.conf

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

  echo "export JAVA_HOME=/usr/local/jdk8u282-b08" >> /etc/profile
  echo "export PATH=\${JAVA_HOME}/bin:\$PATH" >> /etc/profile

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

  echo "export MAVEN_HOME=/usr/local/apache-maven-3.6.3" >> /etc/profile
  echo "export PATH=\${PATH}:\${MAVEN_HOME}/bin" >> /etc/profile

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