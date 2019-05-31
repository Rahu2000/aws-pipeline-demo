#!/bin/bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset REGION
DEFAULT_REGION='ap-northeast-2'

echo 'Would you use registered aws credential?'
echo 'Input Y or N'
read LINE
if [ $LINE == 'Y' ] || [ $LINE == 'y' ]; then
    ACCESS_KEY="$(aws configure get aws_access_key_id)"
    SECRET_KEY="$(aws configure get aws_secret_access_key)"
    if [ -n "$ACCESS_KEY" ] && [ -n "$SECRET_KEY" ]; then
        unset $ACCESS_KEY
        unset $SECRET_KEY
        exit 0
    else
        echo 'AWS Credentials are not set'
    fi
fi
unset LINE

# set AWS_ACCESS_KEY_ID
while :
do
    echo 'Input AWS_ACCESS_KEY_ID:'
    read LINE
    AWS_ACCESS_KEY_ID="$(echo $LINE)"
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        echo 'Invalid data'
    else
        break
    fi
done
unset LINE

# set AWS_SECRET_ACCESS_KEY
while :
do
    echo 'Input AWS_SECRET_ACCESS_KEY:'
    read LINE
    AWS_SECRET_ACCESS_KEY="$(echo $LINE)"
    LINE=''
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo 'Invalid data'
    else
        break
    fi
done
unset LINE

# set REGION

echo 'Input REGION:'
read LINE
REGION="$(echo $LINE)"
if [ -z "$REGION" ]; then
    echo "'$DEFAULT_REGION' will be set as default region"
    REGION=$DEFAULT_REGION
fi

# AWS Configure
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set default.region "$DEFAULT_REGION"
aws configure set default.output json

exit 0