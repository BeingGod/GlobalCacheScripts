#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install server script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
source $SCRIPT_HOME/server_zookeeper.sh # 引入server_zookeeper.sh脚本
source $SCRIPT_HOME/server_globalcache.sh # 引入server_globalcache.sh脚本

function main()
{
cd /home
    server_zookeeper_uninstall # 卸载服务端zookeeper
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:server zookeeper uninstall failed!" ERROR && return 1
    server_globalcache_uninstall # 卸载服务端globalcache
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:server zookeeper uninstall failed!" ERROR && return 1
}
main