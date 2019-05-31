#!/bin/bash
if [ -z "$1" ]; then
    echo "Vpc-id is empty"
    exit 1
fi 
if [ -z "$2" ]; then
    echo "SSH group name is empty"
    exit 1
fi 
if [ -z "$3" ]; then
    echo "Web Service group name is empty"
    exit 1
fi

###################################################
# Get Security Group
###################################################
# SSH Security Group
HAS_SSH_SEC_GROUP="$(aws ec2 describe-security-groups --group-name $2 --filters "Name=vpc-id,Values=$1" 2> /dev/null | jq -r '.SecurityGroups | last(.[]).GroupId')"
# Web Service Security Group
HAS_HTTP_SEC_GROUP="$(aws ec2 describe-security-groups --group-name $3 --filters "Name=vpc-id,Values=$1" 2> /dev/null | jq -r '.SecurityGroups | last(.[]).GroupId')"

###################################################
# Create Security Groups
###################################################
# SSH Security Group
if [ -z $HAS_SSH_SEC_GROUP ] || [ 'null' == $HAS_SSH_SEC_GROUP ]; then
    SSH_SEC_GROUP_ID="$(aws ec2 create-security-group --group-name $2 --description "Security group for SSH access" --vpc-id $1 | jq -r '.GroupId')"
    aws ec2 authorize-security-group-ingress --group-id $SSH_SEC_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SSH_SEC_GROUP_ID --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}]'
fi

# Web Service Security Group
if [ -z $HAS_HTTP_SEC_GROUP ] || [ 'null' == $HAS_HTTP_SEC_GROUP ] ; then
    HTTP_SEC_GROUP_ID="$(aws ec2 create-security-group --group-name $3 --description "Security group for Costom HTTP, HTTPS" --vpc-id $1 | jq -r '.GroupId')"
    aws ec2 authorize-security-group-ingress --group-id $HTTP_SEC_GROUP_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $HTTP_SEC_GROUP_ID --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 8080, "ToPort": 8080, "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}]'
fi

exit 0