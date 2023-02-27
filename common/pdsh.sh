#!/bin/bash
#------------------------------------------------------------------------------------
# Description: GlobalCache pdsh script
# Author: beinggod
# Create: 2023-02-27
#-----------------------------------------------------------------------------------
set -e
function gloablcache_pdsh_usage()
{
  echo "Usage: globalcache_pdsh <command> <all/ceph/client/ceph1/ex_ceph1>"
}

function globalcache_pdsh()
{
  if [ $# -ne 2 ]; then
    gloablcache_pdsh_usage
    return 1
  fi

  pdsh -R ssh -g $2 $1
}