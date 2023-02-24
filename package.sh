#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 项目打包脚本
# Author: beinggod
# Create: 2023-2-24
#-----------------------------------------------------------------------------------
set -e
LOG_FILE=/var/log/globalcache_script.log
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
source $SCRIPT_HOME/common/log.sh

function main()
{
  local package_dir=""
  for name in $(ls $SCRIPT_HOME)
  do
    if [ -d "$SCRIPT_HOME/$name" ]; then
      package_dir+="$name "
    fi
  done

  zip -r GlobalCacheScripts.zip $package_dir
  mv GlobalCacheScripts.zip $SCRIPT_HOME/..

  globalcache_log "------------GlobalCacheScripts package success------------" WARN
}
main
