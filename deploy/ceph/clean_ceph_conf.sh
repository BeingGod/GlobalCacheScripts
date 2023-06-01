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
set "+e"

# 清理ceph环境
function clean_ceph_conf()
{
  globalcache_log "------------clean pdsh start------------" WARN

  pkill ceph

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

  globalcache_log "------------clean ceph end------------" WARN
}

function main()
{
  clean_ceph_conf
}
main