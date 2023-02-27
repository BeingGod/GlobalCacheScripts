#!/bin/bash
#------------------------------------------------------------------------------------
# Description: GlobalCache compile script
# Author: beinggod
# Create: 2023-02-27
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

# 获取pdsh源码
function pdsh_prepare()
{
    globalcache_log "------------pdsh prepare start------------" WARN

    cd /home
    if [ ! -d "pdsh-2.34" ]; then
        tar -zxvf pdsh-2.34.tar.gz
    else
        globalcache_log "The pdsh-2.34 already exists." INFO
    fi

    globalcache_log "------------pdsh prepare end------------" WARN
}

# 编译pdsh
function pdsh_compile()
{
    globalcache_log "------------pdsh compile start------------" WARN
    
    cd /home/pdsh-2.34
    ./configure
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure pdsh makefile failed!" ERROR && return 1
    
    make -j4
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:build pdsh failed!" ERROR && return 1

    make install
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install pdsh failed!" ERROR && return 1

    globalcache_log "------------pdsh compile end------------" WARN
}

# 检查pdsh
function compile_pdsh_check()
{
    globalcache_log "------------pdsh check start------------" WARN
    cd /home
    if [ -f "pdsh-2.34.tar.gz" ]; then
        globalcache_log "pdsh-2.34.tar.gz exists." INFO
    else
        globalcache_log "pdsh-2.34.tar.gz does not exist." WARN
        globalcache_log "Please upload pdsh-2.34.tar.gz to /home." WARN
    fi

    if [ -d "/home/pdsh-2.34" ]; then
        globalcache_log "The pdsh-2.34 already exists." INFO
    else
        globalcache_log "The pdsh-2.34 does not exist." WARN
    fi

    globalcache_log "------------pdsh check end------------" WARN
}

# 构建pdsh
function compile_pdsh_build()
{
    globalcache_log "------------pdsh build start------------" WARN
    pdsh_prepare
    pdsh_compile
    globalcache_log "------------pdsh build end------------" WARN
}

# 清理pdsh
function compile_pdsh_clean()
{
    globalcache_log "------------pdsh clean start------------" WARN

    globalcache_log "rm -rf /home/pdsh-2.34" WARN
    rm -rf /home/pdsh-2.34

    globalcache_log "------------uninstall pdsh bin start------------" WARN
    rm -rf /usr/local/bin/pdsh
    globalcache_log "------------uninstall pdsh bin start------------" WARN

    globalcache_log "------------uninstall pdsh lib start------------" WARN
    rm -rf /usr/local/lib/pdsh
    globalcache_log "------------uninstall pdsh lib end------------" WARN
    
    globalcache_log "------------pdsh clean end------------" WARN
}