#!/bin/bash
unset GIT_USER_NAME
unset GIT_USER_EMAIL
unset REGION
DEFAULT_REGION='ap-northeast-2'

USER_NAME="$(git config -l | grep user.name | cut -d '=' -f 2)"
USER_EMAIL="$(git config -l | grep user.email | cut -d '=' -f 2)"

if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
    echo "Are you $USER_NAME? Y or N"
    read LINE
    if [ $LINE == 'Y' ] || [ $LINE == 'y' ]; then
        unset $USER_NAME
        unset $USER_EMAIL
        exit 0
    fi
fi
unset LINE

# set GIT_USER_NAME
while :
do
    echo 'Input your name:'
    read LINE
    GIT_USER_NAME="$(echo $LINE)"
    if [ -z "$GIT_USER_NAME" ]; then
        echo 'Invalid data'
    else
        break
    fi
done
unset LINE

# set GIT_USER_EMAIL
while :
do
    echo 'Input your email:'
    read LINE
    GIT_USER_EMAIL="$(echo $LINE)"
    if [ -z "$GIT_USER_NAME" ]; then
        echo 'Invalid data'
    else
        break
    fi
done
unset LINE

# git Configure
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# AWS credential configure
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

exit 0