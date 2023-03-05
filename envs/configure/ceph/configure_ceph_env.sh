#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 配置ceph软件环境 (all nodes)
# Author: beinggod
# Create: 2023-2-27
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../../../common/log.sh
source $SCRIPT_HOME/compile_pdsh.sh

# 安装compat-openssl包
function install_compat_openssl()
{
  globalcache_log "------------install compat-openssl start------------" WARN

  cd /home

  # 判断是否安装了compat-openssl
  if [ $(yum list installed | grep "compat-openssl10.aarch64" | wc -l) -eq 0 ]; then
    if [ ! -f "compat-openssl10-1.0.2o-5.fc30.aarch64.rpm" ]; then
      wget https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/30/Everything/aarch64/os/Packages/c/compat-openssl10-1.0.2o-5.fc30.aarch64.rpm --no-check-certificate
      [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:download compat-openssl package failed!" ERROR && return 1
    else
      globalcache_log "The compat-openssl10-1.0.2o-5.fc30.aarch64.rpm is already exist." INFO
    fi
    
    rpm -ivh compat-openssl10-1.0.2o-5.fc30.aarch64.rpm
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install compat-openssl package failed!" ERROR && return 1
  else
    globalcache_log "The compat-openssl already installed." INFO
  fi

  globalcache_log "------------install compat-openssl end------------" WARN

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
  else
    globalcache_log "The firewalld is already closed" INFO
  fi

  globalcache_log "------------close firewall end------------" WARN
}

# 设置主机名
function configure_hostname()
{
  globalcache_log "------------configure hostname start------------" WARN

  local hostname=$(cat /home/script.conf | grep "hostname" | cut -d " " -f 2)

  hostnamectl --static set-hostname $hostname
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure hostname failed!" ERROR && return 1

  cat /home/hostnamelist.txt >> /etc/hosts

  globalcache_log "------------configure hostname end------------" WARN
}

# 设置linux安全模式
function configure_permissive_mode()
{
  globalcache_log "------------configure permissive mode start------------" WARN

  if [[ $(cat /etc/selinux/config | grep "SELINUX=enforcing" | wc -l) -eq 1 ]]; then
    setenforce permissive
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure permissive mode failed!" ERROR && return 1

    sed -i 's/SELINUX=enforcing/SELINUX=permissive' /etc/selinux/config
  else
    globalcache_log "------------Linux is already in permissive mode------------" INFO
  fi

  globalcache_log "------------configure permissive mode end------------" WARN
}

# 配置免密访问
function configure_ssh_key()
{
  globalcache_log "------------configure ssh key start------------" WARN

  # 生成公钥
  if [ $(ls -al /root/.ssh/ | grep id_rsa | wc -l) -eq 0 ]; then
    ssh-keygen -t rsa -N '' << EOF
/root/.ssh/id_rsa
yes


EOF
  else
    globalcache_log "The ssh key is already exist." INFO
  fi

  # 生成失败
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:generate ssh key failed!" ERROR && return 1

  chmod 700 /root/.ssh

  local password=$(cat /home/script.conf | grep password | cut -d ' ' -f 2)

  local ceph_num=$(cat /home/hostnamelist.txt | grep ceph | wc -l)
  local client_num=$(cat /home/hostnamelist.txt | grep client | wc -l)

  # 发送公钥到ceph节点
  for i in $(seq 1 $ceph_num)
  do
      /usr/bin/expect <<EOF
set timeout 5 
spawn ssh-copy-id ceph$i
expect {
  "*yes/no" { send "yes\r"; exp_continue }
  "*password:" { send "$password\r" }
}
expect eof
EOF
  done

  # 发放公钥到client节点
  for i in $(seq 1 $client_num)
  do
      /usr/bin/expect <<EOF
set timeout 5 
spawn ssh-copy-id client$i
expect {
  "*yes/no" { send "yes\r"; exp_continue }
  "*password:" { send "$password\r" }
}
expect eof
EOF
  done

  globalcache_log "------------configure ssh key end------------" WARN
}

# 设置pdsh组
function configure_pdsh_group()
{
  globalcache_log "------------configure pdsh group start------------" WARN

  if [ ! -d "/etc/dsh/group" ]; then
    mkdir -p /etc/dsh/group
  else
    globalcache_log "The /etc/dsh/group is already exist." INFO
  fi

  cat /home/hostnamelist.txt | grep -E -oe "ceph1" > /etc/dsh/group/ceph1                                  # ceph1
  cat /home/hostnamelist.txt | grep -E -oe "ceph[0-9]*" > /etc/dsh/group/ceph                              # all ceph
  cat /home/hostnamelist.txt | grep -E -oe "client[0-9]*" > /etc/dsh/group/client                          # all client
  cat /home/hostnamelist.txt | grep -E -oe "(ceph[0-9]*)|(client[0-9]*)" > /etc/dsh/group/all              # all 
  cat /home/hostnamelist.txt | grep -E -oe "(ceph[2-9]{1}[0-9]*)|(client[0-9]*)" > /etc/dsh/group/ex_ceph1 # exclude ceph1

  globalcache_log "------------configure pdsh group end------------" WARN
}

function main()
{
  # 判断配置文件是否存在
  if [ ! -f "/home/script.conf" ]; then
    globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:Please generate configure file first!" WARN
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi

  local hostname=$(cat /home/script.conf | grep "hostname" | cut -d " " -f 2)

  # 安装compat-openssl
  install_compat_openssl
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  # 关闭防火墙
  close_firewall
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  # 配置节点名
  configure_hostname
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  # 设置linux安全模式
  configure_permissive_mode
  [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

  # 清除已有公钥
  rm -rf /root/.ssh/authorized_keys

  if [[ $hostname = "ceph1" ]]; then
     # 配置SSH互信
    configure_ssh_key
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

     # 编译并安装pdsh
    compile_pdsh_build
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1

    configure_pdsh_group
    [[ $? -ne 0 ]] && globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:configure ceph env failed!" ERROR && return 1
  fi
}
main