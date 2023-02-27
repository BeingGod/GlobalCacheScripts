#!/bin/bash
#------------------------------------------------------------------------------------
# Description: GlobalCache pdsh script
# Author: beinggod
# Create: 2023-02-27
#-----------------------------------------------------------------------------------
set -e
function gloablcache_pdsh_usage()
{
  echo "Usage: globalcache_pdsh <hosts> <command>"
}

function globalcache_pdsh()
{
  if [ $# -ne 2 ]; then
    gloablcache_pdsh_usage
    return 1
  fi

  pdsh -a -w $1 $2
}