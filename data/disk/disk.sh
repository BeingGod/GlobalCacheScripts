#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 除系统盘外的所有磁盘
# Author: beinggod
# Create: 2023-2-23
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# @brief 读取磁盘信息
function main()
{
    local sys_disk_name=$(lsblk | grep "/boot/efi" | grep -oe "sd[a-z]") # 获取系统盘所在磁盘名称
    local all_disk_name=$(lsblk | grep "^[a-z].*" | cut -d ' ' -f 1)
    echo ${all_disk_name//"${sys_disk_name}"/} # 移除系统盘
}
main