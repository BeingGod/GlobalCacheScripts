#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ceph软件环境
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh
source $SCRIPT_HOME/../../../common/pdsh.sh

function main()
{
  if [ ! -f "$SCRIPT_HOME/script.conf" ]; then
    globalcache_log "Please generated script config file first" WARN
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi

  globalcache_pdsh "bash $SCRIPT_HOME/pdsh_configure_ntp_server.sh" ceph1
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  globalcache_pdsh "bash $SCRIPT_HOME/pdsh_configure_ntp_client.sh" ex_ceph1
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
}
main