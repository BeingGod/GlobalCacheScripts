#!/bin/bash
#------------------------------------------------------------------------------------
# Description: ceph安装脚本
#              注意: 该脚本需要使用pdsh调用
# Author: beinggod
# Create: 2023-02-28
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

# 安装ceph
function install_ceph()
{
  globalcache_log "------------install ceph start------------" WARN

  local hostname=$(cat $SCRIPT_HOME/script.conf | grep hostname | cut -d ' ' -f 2)

  echo "sslverify=false
deltarpm=0" >> /etc/yum.conf # 设置yum证书验证状态

  dnf -y install librados2-14.2.8 ceph-14.2.8
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph failed!" ERROR && return 1

  pip install prettytable werkzeug
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install python package failed!" ERROR && return 1

  ceph -v

  globalcache_log "------------install ceph end------------" WARN
}

# 安装ceph-deploy
function install_ceph_deploy_tools()
{
  globalcache_log "------------install ceph deploy tools start------------" WARN

  pip install ceph-deploy
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install python package failed!" ERROR && return 1
  echo "y" | cp $SCRIPT_HOME/__init__.py /lib/python2.7/s

  globalcache_log "------------install ceph deploy tools end------------" WARN
}

function main()
{
  install_ceph
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph failed!" ERROR && return 1

  hostname=$(cat $SCRIPT_HOME/script.conf | grep hostname | cut -d ' ' -f 2)
  if [[ $hostname = "ceph1" ]]; then
    install_ceph_deploy_tools
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ceph deploy tools failed!" ERROR && return 1
  fi
}
main