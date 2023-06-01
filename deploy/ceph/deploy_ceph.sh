#!/bin/bash
#------------------------------------------------------------------------------------
# Description: ceph部署脚本 (ceph1)
# Author: beinggod
# Create: 2023-02-28
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh
set "+e"

# 安装ceph-deploy
function install_ceph_deploy_tools()
{
  globalcache_log "------------install ceph deploy tools start------------" WARN

  pip install ceph-deploy
  echo "y" | cp $SCRIPT_HOME/__init__.py /lib/python2.7/site-packages/ceph_deploy/hosts/

  globalcache_log "------------install ceph deploy tools end------------" WARN
}

# 部署mon节点
function deploy_mon()
{
  globalcache_log "------------deploy mon start------------" WARN

  cd /etc/ceph

  members=""
  while read line
  do
    if [ $(echo $line | grep -E -oe "ceph[0-9]*" | wc -l) -eq 1 ]; then
        members="$members $(echo $line | grep -E -oe "ceph[0-9]*")"
    fi
  done < /home/hostnamelist.txt

  ceph-deploy new $members
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy new members failed!" ERROR && return 1

  members=""
  while read line
  do
    if [ $(echo $line | grep -E -oe "ceph[0-9]*" | wc -l) -eq 1 ]; then
        members="$(echo $line | cut -d ' ' -f 2),$members"
    fi
  done < /home/hostnamelist.txt

  echo "public_network = $(cat /home/script.conf | grep public_network | cut -d ' ' -f 2)
cluster_network =  $(cat /home/script.conf | grep cluster_network | cut -d ' ' -f 2)

bluestore_prefer_deferred_size_hdd = 0
rbd_op_threads=16 # rbd tp线程数
osd_memory_target = 2147483648 # 限制osd内存的参数
bluestore_default_buffered_read = false # 当读取完成时，根据标记决定是否缓存
[mon]
mon_allow_pool_delete = true" >> /etc/ceph/ceph.conf

  ceph-deploy mon create-initial
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:init deploy mon failed!" ERROR && return 1

  nodes=""
  for node in $(cat /home/hostnamelist.txt | grep -E -oe "(ceph[0-9]*)|(client[0-9]*)")
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
  for ceph in $(cat /home/hostnamelist.txt | grep -E -oe "ceph[0-9]*")
  do
    members="$members $ceph"
  done
  
  ceph-deploy mgr create $members
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy mgr failed!" ERROR && return 1

  ceph -s

  globalcache_log "------------deploy mgr end------------" WARN
}

# 部署osd节点
function deploy_osd()
{
  globalcache_log "------------deploy osd start------------" WARN

  cd /etc/ceph

  local ceph=$(cat /home/hostnamelist.txt | grep -E -oe "ceph[0-9]*")
  for node in $ceph
  do
    local nvme_list=$(cat /home/disklist_${node}.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)")
    local nvme_num=$(cat /home/disklist_${node}.txt | grep -E -oe "nvme([0-9]*)n([0-9]*)" | wc -l)
    local data_disk_list=($(cat /home/disklist_${node}.txt | grep -E -oe "sd[a-z]"))
    local data_disk_num=$(cat /home/disklist_${node}.txt | grep -E -oe "sd[a-z]" | wc -l)
    local part_per_nvme=$(expr $data_disk_num / $nvme_num)

    local start=0
    local end=$(expr $part_per_nvme - 1)
    for nvme in $nvme_list
    do
      local j=1
      local k=2
      for index in $(seq $start $end)
      do
        ceph-deploy osd create ${node} --data "/dev/${data_disk_list[${index}]}" --block-wal "/dev/${nvme}p${j}" --block-db "/dev/${nvme}p${k}"
        [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy osd failed!" ERROR && return 1
        ((j=${j}+2))
        ((k=${k}+2))
        sleep 3
      done
      local start=$(expr $start + $part_per_nvme)
      local end=$(expr $end + $part_per_nvme)
    done
  done

  ceph -s

  globalcache_log "------------deploy osd end------------" WARN
}

# 清理osd
function clean_osd()
{
  ceph -s > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    local osd_num=$(ceph -s | grep -o -E "[0-9]+ osds" | awk '{printf $1}')
    if [ $osd_num -ne 0 ]; then
      for i in $(seq 0 `expr $osd_num - 1`)
      do
        i=$1
        ceph osd crush reweight osd.$i 0.0
        pdsh -g ceph "systemctl stop ceph-osd@$i.service"
        ceph osd down osd.$i
        ceph osd out osd.$i
        ceph osd crush remove osd.$i
        ceph osd rm osd.$i
        ceph auth del osd.$i
      done
    fi
  fi
}

function main()
{
  install_ceph_deploy_tools

  # 清理OSD
  # clean_osd

  # 清理Ceph环境
  pdsh -g ceph "bash '$SCRIPT_HOME/clean_ceph_conf.sh'"

  deploy_mon
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1

  deploy_mgr
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1

  deploy_osd
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:deploy ceph failed!" ERROR && return 1
}
main