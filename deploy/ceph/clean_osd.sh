#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 清理ceph环境
# Author: beinggod
# Create: 2023-05-25
#-----------------------------------------------------------------------------------
set -x
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../common/log.sh

function trim_osd()
{
    i=$1
    ceph osd crush reweight osd.$i 0.0
    systemctl stop ceph-osd@$i.service
    ceph osd down osd.$i
    ceph osd out osd.$i
    ceph osd crush remove osd.$i
    ceph osd rm osd.$i
    ceph auth del osd.$i
}

# 清理osd
function main()
{
  ceph -s > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    local osd_num=$(ceph -s | grep -o -E "[0-9]+ osds" | awk '{printf $1}')
    for i in $(seq 0 $osd_num)
    do
      trim_osd $i
    done
  fi
}
main