#!/bin/bash
echo 'launch ec2 for aws codedeploy...'

###################################################
# Set ENVs
###################################################
IMAGE_ID="$(aws ec2 describe-images --owners amazon --filters 'Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')"
INSTANCE_TYPE=t2.micro
INSTANCE_COUNT=1
KEY_NAME='demo'
INSTANCE_ROLE_NAME='AWSCodeDeployRoleforEC2'
#INSTANCE_PROFILE_NAME='EC2InstanceProfileForAWSCodeDeploy'
INSTANCE_VOLUME_SIZE=8
DEPLOY_GROUP_NAME='Demo'
USER_DATA_PATH='assets/ec2_userdata_amazon_ami.txt'
SSH_SEC_GROUP_NAME='SSHAccess'
WEB_SEC_GROUP_NAME='WebService'

###################################################
# Get VPC Info
###################################################
VPC_ID="$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" | jq -r '.Vpcs | last(.[]).VpcId')"
SUBNET_ID="$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" | jq -r '.Subnets | sort_by(.AvailabilityZone) | last(.[]).SubnetId')"

if [ -z $VPC_ID ] | [ -z $SUBNET_ID ]; then
    echo 'Default vpc is not exist'
    exit 8
fi
###################################################
# Get Key Pair
###################################################
echo 'get key pair'

HAS_KEY="$(aws ec2 describe-key-pairs --key-name $KEY_NAME 2> /dev/null | jq -r '.KeyPairs | last(.[]).KeyName')"
if [ -z $HAS_KEY ]; then
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > "$KEY_NAME".pem
    echo "New key file has downloaded at '$(pwd)/$KEY_NAME.pem'"
fi

###################################################
# Get Security Group
###################################################
echo 'create security groups'

./create_security_group.sh $VPC_ID $SSH_SEC_GROUP_NAME $WEB_SEC_GROUP_NAME
if [ $? -ne 0 ]; then
    echo "Failed to create security groups"
    exit 9
fi
SSH_SEC_GROUP_ID="$(aws ec2 describe-security-groups --group-name $SSH_SEC_GROUP_NAME --filters "Name=vpc-id,Values=$VPC_ID" 2> /dev/null | jq -r '.SecurityGroups | last(.[]).GroupId')"
HTTP_SEC_GROUP_ID="$(aws ec2 describe-security-groups --group-name $WEB_SEC_GROUP_NAME --filters "Name=vpc-id,Values=$VPC_ID" 2> /dev/null | jq -r '.SecurityGroups | last(.[]).GroupId')"

###################################################
# Get IAM instance profile for CodeDeploy
###################################################
echo 'create EC2 instance profile'

HAS_PROFILE="$(aws iam get-instance-profile --instance-profile-name $INSTANCE_ROLE_NAME 2> /dev/null | jq -r '.InstanceProfile.InstanceProfileName')"
if [ -z $HAS_PROFILE ] || [ 'null' == $HAS_PROFILE ] ; then
    ./create_ec2_profile.sh $INSTANCE_ROLE_NAME $INSTANCE_PROFILE_NAME
    if [ $? -ne 0 ]; then
        echo "Failed to create instance profile."
        exit 9
    fi
fi

###################################################
# Generate Instance
###################################################
# Launch EC2 Instance
echo 'Launch EC2 Instance'

sleep 10
INSTANCE_PROFILE="$(aws iam get-instance-profile --instance-profile-name $INSTANCE_ROLE_NAME 2> /dev/null | jq -r '.InstanceProfile.InstanceProfileName')"

if [ -z $INSTANCE_PROFILE ] || [ 'null' == $INSTANCE_PROFILE ] ; then
    echo "Failed to create instance profile."
    exit 9
fi
INSTANCE_ID="$(aws ec2 run-instances --image-id $IMAGE_ID --count $INSTANCE_COUNT --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SSH_SEC_GROUP_ID $HTTP_SEC_GROUP_ID --subnet-id $SUBNET_ID --block-device-mappings "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":$INSTANCE_VOLUME_SIZE,\"DeleteOnTermination\":true}}]" --user-data file://$USER_DATA_PATH --iam-instance-profile Name=$INSTANCE_PROFILE | jq -r '.Instances | last(.[]).InstanceId')" 

# Tag for CodeDeploy
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$DEPLOY_GROUP_NAME

exit 0