#!/bin/bash

# 禁用fedora源
if [ -f "/etc/yum.repos.d/fedora.repo" ]; then
sed -i "s/enabled=1/enabled=0/g" /etc/yum.repos.d/fedora.repo
fi

yum remove -y openssl openssl-devel

yum install -y openssl-1:1.1.1f-1.oe1 openssl-libs-1:1.1.1f-1.oe1 --allowerasing