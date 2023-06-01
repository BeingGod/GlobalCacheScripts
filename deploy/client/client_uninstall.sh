#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install client script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
source $SCRIPT_HOME/client_zookeeper.sh # 引入client_zookeeper.sh脚本
source $SCRIPT_HOME/client_globalcache.sh # 引入client_globalcache.sh脚本
set "+e"

function main()
{
cd /home
    client_zookeeper_uninstall # 卸载客户端zookeeper
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:client zookeeper uninstall failed!" ERROR && return 1
    client_globalcache_uninstall # 卸载客户端globalcache
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:client globalcache uninstall failed!" ERROR && return 1
}
main