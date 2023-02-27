#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ceph软件环境
# Author: beinggod
# Create: 2023-2-25
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh

function usage()
{
  echo "Usage: configure_ceph_env.sh <hostname>"
}

# 安装compat-openSSL包
function install_compat_openSSL()
{
  globalcache_log "------------install compat-openSSL start------------" WARN

  # 判断是否安装了compat-openssl
  if [ $(yum list installed | grep "compat-openssl10.aarch64" | wc -l) -eq 0 ]; then
    if [ ! -f compat-openssl10-1.0.2o-5.fc30.aarch64.rpm ]; then
      wget https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/30/Everything/aarch64/os/Packages/c/compat-openssl10-1.0.2o-5.fc30.aarch64.rpm --no-check-certificate
      [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:download compat-openssl package failed!" ERROR && return 1
    fi
    
    rpm -ivh compat-openssl10-1.0.2o-5.fc30.aarch64.rpm
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install compat-openssl package failed!" ERROR && return 1
  fi

  globalcache_log "------------install compat-openSSL end------------" WARN

  return 0
}

# 关闭防火墙
function close_firewall()
{
  globalcache_log "------------close firewall start------------" WARN

  # 判断当前防火墙是否已经关闭
  if [[ $(systemctl status firewalld | grep inactive | wc -l) -ne 1 ]]; then
    systemctl stop firewalld
    systemctl disable firewalld
  fi
  systemctl status firewalld

  globalcache_log "------------close firewall end------------" WARN
}

# 设置主机名
function configure_hostname()
{
  globalcache_log "------------configure hostname start------------" WARN

  hostnamectl --static set-hostname $1
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure hostname failed!" ERROR && return 1

  cat $SCRIPT_HOME/hostnamelist.txt >> /etc/hosts

  globalcache_log "------------configure hostname end------------" WARN
}

# 配置ntp服务
function configure_ntp()
{
  globalcache_log "------------configure ntp start------------" WARN

  local hostname=$1

  # 判断ntp是否安装
  yum -y install ntp ntpdate
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install ntp failed!" ERROR && return 1
  
  mv /etc/ntp.conf /etc/ntp.conf.bak

  if [ -f /etc/ntp.conf ]; then
    rm -rf /etc/ntp.conf
  fi

  # 更新配置ntpd文件
  if [[ $hostname = "ceph1" ]]; then
    cat $SCRIPT_HOME/server_ntp.conf > /etc/ntp.conf
  else
    cat $SCRIPT_HOME/client_ntp.conf > /etc/ntp.conf
  fi

  # 判断ntpd服务是否开启
  if [[ $(systemctl status ntpd | grep active | wc -l) -ne 1 ]]; then
    systemctl start ntpd 
    systemctl enable ntpd 
  fi
  systemctl status ntpd

  if [[ $hostname != "ceph1" ]]; then
    # 同步时间
    ntpdate ceph1
    hwclock -w

    # 安装crontab定时服务
    yum install -y crontabs
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install crontabs failed!" ERROR && return 1

    if [[ $(systemctl status crond | grep active | wc -l 1) -ne 1 ]]; then
      systemctl enable crond.service
      systemctl start crond 
    fi
    systemctl status crond

    # 添加定时任务
    local server_ip=$(cat $SCRIPT_HOME/client_ntp.conf | grep -E -oe "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
    echo "*/10 * * * * /usr/sbin/ntpdate $server_ip" | crontab -     
  fi

  globalcache_log "------------configure ntp end------------" WARN
}

# 配置免密访问
function configure_ssh_key()
{
  globalcache_log "------------configure ntp ssh key start------------" WARN

  # 生成公钥
  if [ $(ls -al /root/.ssh/ | grep id_rsa | wc -l) -eq 0 ]; then
    ssh-keygen -t rsa -N '' << EOF
/root/.ssh/id_rsa
yes


EOF
  fi

  # 生成失败
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:generate ssh key failed!" ERROR && return 1

  chmod 700 /root/.ssh

  local ceph_num=$(cat $SCRIPT_HOME/hostnamelist.txt | grep ceph | wc -l)
  local client_num=$(cat $SCRIPT_HOME/hostnamelist.txt | grep client | wc -l)

  # 发放公钥到其他节点
  for i in $(seq 1 $ceph_num); do ssh-copy-id -f ceph$i; done
  for i in $(seq 1 $client_num); do ssh-copy-id -f client$i; done

  globalcache_log "------------configure ntp ssh key end------------" WARN
}

# 设置linux安全模式
function configure_permissive_mode()
{
  globalcache_log "------------configure permissive mode start------------" WARN

  if [[ $(cat /etc/selinux/config | grep "SELINUX=enforcing" | wc -l) -eq 1 ]]; then
    setenforce permissive
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure permissive mode failed!" ERROR && return 1

    sed -i 's/SELINUX=enforcing/SELINUX=permissive' /etc/selinux/config
  fi

  globalcache_log "------------configure permissive mode end------------" WARN
}

function main()
{
  pushd /home

  local hostname=$1

  if [[  -z $hostname ]]; then
    usage
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi

  install_compat_openSSL
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  close_firewall
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  configure_hostname $hostname
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  configure_ntp $hostname
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  if [[ $hostname = "ceph1" ]]; then
    configure_ssh_key
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi

  configure_permissive_mode
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  popd
}
main $1