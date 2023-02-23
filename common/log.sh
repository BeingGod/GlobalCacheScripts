#!/bin/bash
#------------------------------------------------------------------------------------
# Copyright: Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
# Description: GlobalCache log script
# Author: xc
# Create: 2022-04-01
#-----------------------------------------------------------------------------------
set -e
VERSION=1.1.0
function globalcache_log()
{
    if [ $# -eq 2 ]; then
        log_level=$2
    else
        log_level="error"
    fi
    if [[ "$log_level" = "info" || "$log_level" = "INFO" ]];then
        echo "[$(date "+%Y-%m-%d %T")][$log_level]$1" >> ${LOG_FILE}
    else
        echo "[$(date "+%Y-%m-%d %T")][$log_level]$1" | tee -a ${LOG_FILE}
    fi
}
