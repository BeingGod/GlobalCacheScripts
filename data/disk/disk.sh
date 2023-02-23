#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 系统可用磁盘
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
    local sys_disk_name=$(lsblk |grep "/boot/efi"  | cut -c 3-11 | awk '{sub(/^ */, "");sub(/ *$/, "")}1') # 获取系统盘所在磁盘分区名称并去除行尾空格
    local sys_disk_name=${sys_disk_name::-1} # 去掉末尾的数字，非Nvme只保留盘号，Nvme还有一个p等待处理
    local sys_disk_name=${sys_disk_name%%p*} # 去除Nvme末尾的p，非Nvme本行无操作
    local usable_disk_list=$(lsblk -d -o name,rota |grep -v "NAME" | grep -v "${sys_disk_name}") # 1为机械0为固态
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:read disk failed!" ERROR && return 1
    echo $usable_disk_list
}
main


