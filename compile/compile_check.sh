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
source $SCRIPT_HOME/compile_client.sh # 引入compile_client.sh脚本
source $SCRIPT_HOME/compile_server.sh # 引入compile_server.sh脚本

function main()
{
cd /home
    compile_liboath_check # 检查liboath
    compile_zookeeper_check # 检查zookeeper
    compile_client_check # 检查client
    compile_server_check # 检查server
}
main