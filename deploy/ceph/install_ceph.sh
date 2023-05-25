#!/bin/bash
#------------------------------------------------------------------------------------
# Description: ceph安装脚本 (all ceph)
# Author: beinggod
# Create: 2023-02-28
#-----------------------------------------------------------------------------------
set -x
set -e # 遇到错误停止执行
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

# 安装ceph
function install_ceph()
{
  globalcache_log "------------install ceph start------------" WARN

  if [ $(cat "/etc/yum.conf" | grep -oe "sslverify=false" | wc -l) -eq 0 ]; then
    echo "sslverify=false" >> /etc/yum.conf # 设置yum证书验证状态
  fi

  if [ $(cat "/etc/yum.conf" | grep -oe "deltarpm=0" | wc -l) -eq 0 ]; then
    echo "deltarpm=0" >> /etc/yum.conf # 设置yum证书验证状态
  fi

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
  echo "y" | cp $SCRIPT_HOME/__init__.py /lib/python2.7/site-packages/ceph_deploy/hosts/

  globalcache_log "------------install ceph deploy tools end------------" WARN
}

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

  for nvme in $nvme_list
  do
    parted -s /dev/$nvme mklabel gpt
    sleep 10
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

  for data_disk in $data_disk_list
  do
    ceph-volume lvm zap /dev/$data_disk --destroy
    sleep 10
  done

  globalcache_log "------------partition end------------" WARN
}

# 清理ceph环境
function clean_ceph()
{
  ceph -s > /dev/null 2>&1

  # 清理osd
  if [ $? -eq 0 ]; then
    local osd_num=$(ceph -s | grep -o -E "[0-9]+ osds" | awk '{printf $1}')
    for i in $(seq 0 $osd_num)
    do
      bash $SCRIPT_HOME/trim_osd.sh $i
    done
  fi

  pkill ceph

  rm -rf /etc/ceph/ceph.conf

  rm -rf /var/lib/ceph/osd/*
  rm -rf /var/lib/ceph/mon/*
  rm -rf /var/lib/ceph/mds/*
  rm -rf /var/lib/ceph/bootstrap-mds/*
  rm -rf /var/lib/ceph/bootstrap-osd/*
  rm -rf /var/lib/ceph/bootstrap-rgw/*
  rm -rf /var/lib/ceph/bootstrap-mgr/*
  rm -rf /var/lib/ceph/tmp/*
  rm -rf /etc/ceph/*
  rm -rf /var/run/ceph/*
}

function main()
{
  install_ceph

  realhostname=$(hostname)
  if [[ $realhostname = "ceph1" ]]; then
    install_ceph_deploy_tools
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph deploy tools failed!" ERROR && return 1
  fi

  partition

  clean_ceph
}
main