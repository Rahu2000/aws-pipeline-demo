#!/bin/bash
OS_TYPE="$(awk -F= '/^NAME/{print $2}' /etc/*-release | tr -d \")"

if [ ! -d ".config" ]; then
    mkdir .config
fi

# OS type Check
if [ "$OS_TYPE" == "Ubuntu" ]; then
    ./ubuntu_env.sh
    exit 0
fi
if [ "$OS_TYPE" == "CentOS" ]; then
    ./centos_env.sh
    exit 0
fi

echo 'Not Support OS'
exit 1
