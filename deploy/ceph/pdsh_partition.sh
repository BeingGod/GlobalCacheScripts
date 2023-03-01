#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 磁盘分区脚本
#              注意: 该脚本需要使用pdsh调用
# Author: beinggod
# Create: 2023-03-1
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

function partition()
{
  globalcache_log "------------partition start------------" WARN

  local nvme_list=$(cat $SCRIPT_HOME/disklist.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)")
  local nvme_num=$(echo $nvme_list | wc -l)
  for nvme in $nvme_list
  do
    # parted -s /dev/$nvme mklabel gpt
    echo "parted -s /dev/$nvme mklabel gpt"
  done
  
  local data_disk_list=$(cat $SCRIPT_HOME/disklist.txt | grep -E -oe "sd[a-z]")
  local data_disk_num=$(echo $data_disk_list | wc -l)
  local part_per_nvme=$(expr $data_disk_num / $nvme_num)
  local start=4
  for i in $(seq 1 $part_per_nvme)
  do
    local end=`expr $start + 10240`
    for nvme in $nvme_list
    do
      # parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB
      echo "parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB"
    done
    local start=$end

    local end=`expr $start + 25600`
    for nvme in $nvme_list
    do
      # parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB
      echo "parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB"
    done
    local start=$end
  done

  for nvme in $nvme_list
  do
    # parted /dev/$nvme mkpart primary ${end}MiB 100%
    echo "parted /dev/$nvme mkpart primary ${end}MiB 100%"
  done

  for data_disk in $data_disk_list
  do
    # ceph-volume lvm zap /dev/$data_disk --destroy
    echo "ceph-volume lvm zap /dev/$data_disk --destroy"
  done

  globalcache_log "------------partition end------------" WARN
}
partition