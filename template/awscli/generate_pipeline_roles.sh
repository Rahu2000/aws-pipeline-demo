#!/bin/bash
CODEPIPELINE_ROLE_NAME='TestPipelineRole'
CODEPIPELINE_POLICY_NAME='TestPolicy'
CODEDEPLOY_ROLE_NAME='TestDeployRole'
EC2_ROLE_NAME='TestEC2Role'

#######
# create codepipeline policy
CODEPIPELINE_POLICY_ARN="$(aws iam create-policy --policy-name $CODEPIPELINE_POLICY_NAME --policy-document file://policies/AWSCodePipelineServiceRole.json | jq .Policy.Arn | tr -d \")"

# create codepipeline role
aws iam create-role --role-name $CODEPIPELINE_ROLE_NAME --assume-role-policy-document file://policies/TrustPolicyForCodePipeline.json

# attach policy to codepipeline role
aws iam attach-role-policy --policy-arn $CODEPIPELINE_POLICY_ARN --role-name $CODEPIPELINE_ROLE_NAME
#######

#######
# create codedeploy role
aws iam create-role --role-name $CODEDEPLOY_ROLE_NAME --assume-role-policy-document file://policies/TrustPolicyForCodeDeploy.json

# attach policy to codedeploy role
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole --role-name $CODEDEPLOY_ROLE_NAME
#######

#######
# create ec2 role for codedeploy
aws iam create-role --role-name $EC2_ROLE_NAME --assume-role-policy-document file://policies/TrustPolicyForEC2.json

# attach policy to codedeploy role
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy --role-name $EC2_ROLE_NAME
#######
