#!/bin/bash
#------------------------------------------------------------------------------------
# Description: 检查Ceph部署情况
# Author: beinggod
# Create: 2023-03-19
#-----------------------------------------------------------------------------------
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh
set "+e"

function ceph_check()
{
    globalcache_log "------------check ceph start------------" WARN

    if ceph -s > /dev/null 2>&1; then
        ceph -s
    else
        globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check ceph failed!" FATAL
    fi

    local realhostname=$(hostname)
    if [ $realhostname = "ceph1" ]; then
        osd_num=0
        while read line
        do
            if [ $(echo $line | grep -E -oe "ceph[0-9]*" | wc -l) -eq 1 ]; then
                local hostname=$(echo $line | grep -E -oe "ceph[0-9]*")
                local data_disk_num=$(cat "/home/disklist_${hostname}.txt" | grep -E -oe "sd[a-z]" | wc -l)
                osd_num=$(expr $osd_num + $data_disk_num)
            fi
        done < /home/hostnamelist.txt

        if [ $(ceph -s | grep -o -E "[0-9]+ osds" | awk '{printf $1}') -ne $osd_num ]; then
            globalcache_log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:check ceph failed, osd deploy failed!" FATAL 
        fi
    fi

    globalcache_log "------------check ceph end------------" WARN
}

function ntp_check()
{
    globalcache_log "------------ceph ntpd check start------------" WARN

    local realhostname=$(hostname)
    if [ $realhostname = "ceph1" ]; then
        local state=$(systemctl status ntpd | grep -oe "running" | wc -l)
        if [ $state -eq 0 ]; then
            globalcache_log "------------ntpd service check failed!------------" FATAL 
        fi
    fi
    
    globalcache_log "------------ceph ntpd check end------------" WARN
}

function main()
{
cd /home
    ceph_check

    ntp_check
}
main