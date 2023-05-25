#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 清理ceph环境
# Author: beinggod
# Create: 2023-05-25
#-----------------------------------------------------------------------------------
set -x

# 清理ceph环境
function clean_ceph()
{
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
}

clean_ceph