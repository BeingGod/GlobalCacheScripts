#!/bin/bash
#------------------------------------------------------------------------------------
# Description: ceph安装脚本 (all ceph)
# Author: beinggod
# Create: 2023-02-28
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# 安装ceph
function install_ceph()
{
  globalcache_log "------------install ceph start------------" WARN

  local hostname=$(cat /home/script.conf | grep hostname | cut -d ' ' -f 2)

  echo "sslverify=false
deltarpm=0" >> /etc/yum.conf # 设置yum证书验证状态

  dnf -y install librados2-14.2.8 ceph-14.2.8

  pip install prettytable werkzeug

  ceph -v

  globalcache_log "------------install ceph end------------" WARN
}

# 安装ceph-deploy
function install_ceph_deploy_tools()
{
  globalcache_log "------------install ceph deploy tools start------------" WARN

  pip install ceph-deploy
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install python package failed!" ERROR && return 1
  echo "y" | cp $SCRIPT_HOME/__init__.py /lib/python2.7/s

  globalcache_log "------------install ceph deploy tools end------------" WARN
}

# 划分磁盘分区
function partition()
{
  globalcache_log "------------partition start------------" WARN

  local nvme_list=$(cat /home/disklist.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)")
  local nvme_num=$(echo $nvme_list | wc -l)
  for nvme in $nvme_list
  do
    parted -s /dev/$nvme mklabel gpt
  done
  
  local data_disk_list=$(cat /home/disklist.txt | grep -E -oe "sd[a-z]")
  local data_disk_num=$(echo $data_disk_list | wc -l)
  local part_per_nvme=$(expr $data_disk_num / $nvme_num)
  local start=4
  for i in $(seq 1 $part_per_nvme)
  do
    local end=`expr $start + 10240`
    for nvme in $nvme_list
    do
      parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB
    done
    local start=$end

    local end=`expr $start + 25600`
    for nvme in $nvme_list
    do
      parted /dev/$nvme mkpart primary ${start}MiB ${end}MiB
    done
    local start=$end
  done

  local ccm_part_num=`expr $part_per_nvme * 2 + 1`

  for nvme in $nvme_list
  do
    parted /dev/$nvme mkpart primary ${end}MiB 100%
    sed -i "s/<device>/${nvme}p${ccm_part_num}" /home/nodelists.txt
  done

  for data_disk in $data_disk_list
  do
    ceph-volume lvm zap /dev/$data_disk --destroy
  done

  globalcache_log "------------partition end------------" WARN
}

function main()
{
  install_ceph
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph failed!" ERROR && return 1

  hostname=$(cat /home/script.conf | grep hostname | cut -d ' ' -f 2)
  if [[ $hostname = "ceph1" ]]; then
    install_ceph_deploy_tools
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph deploy tools failed!" ERROR && return 1
  fi

  partition
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph deploy tools failed!" ERROR && return 1
}
main