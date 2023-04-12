#------------------------------------------------------------------------------------
# Description: 安装pdsh
# Author: beinggod
# Create: 2023-4-12
#-----------------------------------------------------------------------------------
set -e
SCRIPT_HOME=$(cd $(dirname $0)/; pwd)
LOG_FILE=/var/log/globalcache_script.log
source $SCRIPT_HOME/../common/log.sh

# 安装pdsh
function install_pdsh()
{
    globalcache_log "------------install pdsh start------------" WARN

    yum install pdsh -y
    [[ $? -ne 0 ]] && log "[$BASH_SOURCE,$LINENO,$FUNCNAME]:install pdsh failed!" ERROR && return 1

    globalcache_log "------------install pdsh end------------" WARN 
}

function main()
{
    install_pdsh
}
main