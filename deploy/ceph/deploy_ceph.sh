#!/bin/bash
#------------------------------------------------------------------------------------
# Description: ceph部署脚本 (ceph1)
# Author: beinggod
# Create: 2023-02-28
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# 部署mon节点
function deploy_mon()
{
  globalcache_log "------------deploy mon start------------" WARN

  cd /etc/ceph

  local members=""
  for ceph in $(cat $SCRIPT_HOME/hostnamelist.txt | grep -E -oe "ceph[0-9]*")
  do
    members="$members $ceph"
  done
  
  ceph-deploy new $members
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy new members failed!" ERROR && return 1

  local members=""
  local hosts=""
  for line in $(cat $SCRIPT_HOME/hostnamelist.txt | grep -E "ceph[0-9]*")
  do
    members="$members,$(echo $line | cut -d ' ' -f 2)"
    hosts="$hosts,$(echo $line | cut -d ' ' -f 1)"
  done

  if [ -f "/etc/ceph/ceph.conf" ]; then
    rm -rf /etc/ceph/ceph.conf
  fi

  echo "[global]
fsid = $uuidgen
mon_initial_members = $members
mon_host = $hosts
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

public_network = $(cat $SCRIPT_HOME/script.conf | grep public_network | cut -d ' ' -f 2)
cluster_network =  $(cat $SCRIPT_HOME/script.conf | grep public_network | cut -d ' ' -f 2)

bluestore_prefer_deferred_size_hdd = 0
rbd_op_threads=16 # rbd tp线程数
osd_memory_target = 2147483648 # 限制osd内存的参数
bluestore_default_buffered_read = false # 当读取完成时，根据标记决定是否缓存
[mon]
mon_allow_pool_delete = true" > /etc/ceph/ceph.conf

  ceph-deploy mon create-initial 
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:init deploy mon failed!" ERROR && return 1

  local nodes=""
  for node in $(cat $SCRIPT_HOME/hostnamelist.txt | grep -E -oe "(ceph[0-9]*)|(client[0-9]*)")
  do
    nodes="$nodes $node"
  done

  ceph-deploy --overwrite-conf admin $nodes
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:distribute keyring failed!" ERROR && return 1

  ceph -s

  globalcache_log "------------deploy mon end------------" WARN
}

# 部署mgr节点
function deploy_mgr()
{
  globalcache_log "------------deploy mgr start------------" WARN

  cd /etc/ceph

  local members=""
  for ceph in $(cat $SCRIPT_HOME/hostnamelist.txt | grep -E -oe "ceph[0-9]*")
  do
    members="$members $ceph"
  done
  
  ceph-deploy mgr create new $members
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy mgr failed!" ERROR && return 1

  ceph -s

  globalcache_log "------------deploy mgr end------------" WARN
}

# 部署osd节点
function deploy_osd()
{
  globalcache_log "------------deploy osd start------------" WARN

  cd /etc/ceph

  local ceph=$(cat $SCRIPT_HOME/hostnamelist.txt | grep -E -oe "ceph[0-9]*")
  local nvme_list=$(cat $SCRIPT_HOME/disklist.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)")
  local nvme_num=$(cat $SCRIPT_HOME/disklist.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)" | wc -l)
  local data_disk_list=($(cat $SCRIPT_HOME/disklist.txt | grep -E -oe "sd[a-z]"))
  local data_disk_num=$(cat $SCRIPT_HOME/disklist.txt | grep -E -oe "sd[a-z]" | wc -l)
  local part_per_nvme=$(expr $data_disk_num / $nvme_num)
  for node in $ceph
  do
    local start=0
    local end=$(expr $part_per_nvme - 1)
    for nvme in $nvme_list
    do
      local j=1
      local k=2
      for index in $(seq $start $end)
      do
        ceph-deploy osd create ${node} --data '/dev/${data_disk_list[${index}]}' --block-wal '/dev/${nvme}p${j}' --block-db '/dev/${nvme}p${k}'
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy osd failed!" ERROR && return 1
        ((j=${j}+2))
        ((k=${k}+2))
        sleep 3
      done
      local start=$(expr $start + $part_per_nvme)
      local end=$(expr $end + $part_per_nvm)
    done
  done

  ceph -s

  globalcache_log "------------deploy osd end------------" WARN
}

function main()
{
  if [ ! -f "$SCRIPT_HOME/script.conf" ]; then
    globalcache_log "Please generated script config file first" WARN
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1
  fi

  deploy_mon
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1

  deploy_mgr
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1

  deploy_osd
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1
}
main