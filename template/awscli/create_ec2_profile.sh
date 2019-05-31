#!/bin/bash
if [ -z "$1" ]; then
    echo 'Role name is empty'
    exit 1
fi

# create ec2 role for codedeploy
aws iam create-role --role-name $1 --assume-role-policy-document file://policies/TrustPolicyForEC2.json

# attach policy to codedeploy role
aws iam attach-role-policy --role-name $1 --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy 

# Create the instance profile required by EC2 to contain the role
aws iam create-instance-profile --instance-profile-name $1

# Finally, add the role to the instance profile
aws iam add-role-to-instance-profile --instance-profile-name $1 --role-name $1

exit 0