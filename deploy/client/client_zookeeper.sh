#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache install client script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
set -x
source ../../common/log.sh

# 安装zookeeper
function client_zookeeper_install()
{
    globalcache_log "-----------install client zookeeper start-----------" WARN

    \cp /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/include/zookeeper/* /usr/include
    \cp /home/apache-zookeeper-3.6.3/zookeeper-client/zookeeper-client-c/target/c/lib/* /usr/lib64

    globalcache_log "-----------install client zookeeper end-----------" WARN
}

# 删除zookeeper头文件
function client_zookeeper_include_uninstall()
{
    globalcache_log "-----------uninstall client zookeeper include start-----------" WARN

    echo "rm -rf /usr/include/proto.h"
    rm -rf /usr/include/proto.h
    echo "rm -rf /usr/include/recordio.h"
    rm -rf /usr/include/recordio.h
    echo "rm -rf /usr/include/zookeeper.h"
    rm -rf /usr/include/zookeeper.h
    echo "rm -rf /usr/include/zookeeper.jute.h"
    rm -rf /usr/include/zookeeper.jute.h
    echo "rm -rf /usr/include/zookeeper_log.h"
    rm -rf /usr/include/zookeeper_log.h
    echo "rm -rf /usr/includezookeeper_version.h"
    rm -rf /usr/include/zookeeper_version.h

    globalcache_log "-----------uninstall client zookeeper include end-----------" WARN
}

# 删除zookeeper库文件
function client_zookeeper_lib_uninstall()
{
    globalcache_log "-----------uninstall client zookeeper lib start-----------" WARN

    echo "rm -rf /usr/lib64/libzookeeper_*"
    rm -rf /usr/lib64/libzookeeper_*

    globalcache_log "-----------uninstall client zookeeper lib end-----------" WARN
}


# 卸载zookeeper
function client_zookeeper_uninstall()
{
    globalcache_log "-----------uninstall client zookeeper start-----------" WARN

    client_zookeeper_include_uninstall
    client_zookeeper_lib_uninstall

    globalcache_log "-----------uninstall client zookeeper end-----------" WARN
}