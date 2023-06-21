#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 格式化脚本 
# Author: beinggod
# Create: 2023-02-28
#-----------------------------------------------------------------------------------
set -x
set -e # 遇到错误停止执行
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

# 划分磁盘分区
function partition()
{
  globalcache_log "------------partition start------------" WARN

  local nvme_list=$(cat /home/disklist.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)")
  local nvme_num=$(cat /home/disklist.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)" | wc -l)

  local data_disk_list=$(cat /home/disklist.txt | grep -E -oe "sd[a-z]")
  local data_disk_num=$(cat /home/disklist.txt | grep -E -oe "sd[a-z]" | wc -l)
  local part_per_nvme=$(expr $data_disk_num / $nvme_num)
  local ccm_part_num=`expr $part_per_nvme \* 2 + 1`
  for nvme in $nvme_list
  do
    sed -i "s#<device>#${nvme}p${ccm_part_num}#" /home/nodelist.txt
  done

  for data_disk in $data_disk_list
  do
    parted -s /dev/$data_disk mklabel gpt
    ceph-volume lvm zap /dev/$data_disk --destroy
  done

  for nvme in $nvme_list
  do
    parted -s /dev/$nvme mklabel gpt
    sleep 5
  done

  local start=4
  for i in $(seq 1 $part_per_nvme)
  do
    local end=`expr $start + 10240`
    for nvme in $nvme_list
    do
      parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB
      sleep 10
    done
    local start=$end

    local end=`expr $start + 25600`
    for nvme in $nvme_list
    do
      parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB
      sleep 10
    done
    local start=$end
  done

  for nvme in $nvme_list
  do
    parted /dev/$nvme mkpart primary ${end}MiB 100%
    sleep 10
  done

  globalcache_log "------------partition end------------" WARN
}

function main()
{
  partition
}
main