#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 清理ceph环境
# Author: beinggod
# Create: 2023-05-25
#-----------------------------------------------------------------------------------
set -x

function clean_osd()
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

clean_osd $1