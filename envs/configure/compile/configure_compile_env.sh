#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置编译节点环境
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

function configure_compile() 
{
    globalcache_log "------------Configure compile node environment start------------" WARN
    
    cd /home

    # 检查依赖包是否上传完毕
    if [ ! -f "/home/OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz" ] ; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:not found java package!" ERROR && return 1
    fi

    if [ ! -f "/home/apache-maven-3.6.3-bin.tar.gz" ] ; then
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:not found maven package!" ERROR && return 1
    fi

    # 设置yum证书验证状态为不验证
    echo -e 'sslverify=false\ndeltarpm=0' >> /etc/yum.conf
    
    # 配置pip华为代理
    if [ ! -d "~/.pip" ] ; then
      mkdir -p ~/.pip
    fi

    echo -e '[global]\ntimeout = 120\nindex-url = https://repo.huaweicloud.com/repository/pypi/simple\ntrusted-host = repo.huaweicloud.com' >> ~/.pip/pip.conf

    # 配置Java
    tar -zxvf OpenJDK8U-jdk_aarch64_linux_hotspot_jdk8u282-b08.tar.gz -C /usr/local/
    echo -e 'export JAVA_HOME=/usr/local/jdk8u282-b08\nexport PATH=${JAVA_HOME}/bin:$PATH' >> /etc/profile
    
    # 配置maven
    tar -zxvf apache-maven-3.6.3-bin.tar.gz -C /usr/local
    cp -f $SCRIPT_HOME/settings.xml.template /usr/local/apache-maven-3.6.3/conf/settings.xml
    echo -e 'MAVEN_HOME=/usr/local/apache-maven-3.6.3\nexport MAVEN_HOME\nexport PATH=${PATH}:$MAVEN_HOME/bin' >> /etc/profile

    source /etc/profile

    java -version
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure java failed!" ERROR && return 1

    mvn -v
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure maven failed!" ERROR && return 1

    globalcache_log "------------Configure compile node environment end------------" WARN
}

function main()
{
   configure_compile
}
main