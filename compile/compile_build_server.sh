#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache compile script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
source $SCRIPT_HOME/compile_liboath.sh # 引入compile_liboath.sh脚本
source $SCRIPT_HOME/compile_zookeeper.sh # 引入compile_zookeeper.sh脚本
source $SCRIPT_HOME/compile_server.sh # 引入compile_server.sh脚本
set "-e"
cpu_type=$(uname -m)
function main()
{
cd /home
    compile_liboath_build # 编译liboath
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:compile liboath failed!" ERROR && return 1
    compile_zookeeper_build # 编译zookeeper
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:compile zookeeper failed!" ERROR && return 1
    if [ "${cpu_type}" = "aarch64" ] ; then 
        compile_server_build # 编译server
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:compile server failed!" ERROR && return 1
    fi
}
main