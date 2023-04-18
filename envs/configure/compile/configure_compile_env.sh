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

function main()
{
    configure_compile
}
main