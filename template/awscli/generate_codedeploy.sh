#!/bin/bash
if [ -z "$1" ]; then
    echo 'Application name is empty'
    exit 1
fi

# Set application name
APP_NAME="$1"
PLATFORM="$2"
BRANCH="$3"

CODEDEPLOY_SERVICE_ROLE='CodeDeployServiceRole'

# Set deployment group name
if [ -z $BRANCH ]; then
    DEPLOYMENT_NAME=$APP_NAME-deployment
else 
    DEPLOYMENT_NAME=$APP_NAME-$BRANCH-deployment
fi

# Set default platform
if [ -z $PLATFORM ]; then
    PLATFORM="Server"
fi

# Validate platform
if [[ ! $PLATFORM =~ ^(Server|Lambda|ECS)$ ]]; then
    echo "Platform $PLATFORM is not supported"
    echo "Supported platforms are 'Server|Lambda|ECS'"
    exit 9
fi

##############################################
# create application
##############################################
# Get ApplicationId
APP_ID="$(aws deploy get-application --application-name $APP_NAME 2> /dev/null | jq -r '.application.applicationId')"

if [ -z $APP_ID ]; then
    APP_ID="$(aws deploy create-application --application-name $APP_NAME --compute-platform $PLATFORM| jq -r '.applicationId')"
fi

##############################################
# create application deployment group
##############################################
ROLE_ARN="$(aws iam get-role --role-name $CODEDEPLOY_SERVICE_ROLE 2> /dev/null | jq -r '.Role.Arn')"
if [ -z $ROLE_ARN ]; then
    echo 'Service role is not found'
    exit 9
fi

# EC2 Type deployment
if [ 'Server' == $PLATFORM ]; then
    aws deploy create-deployment-group \
        --application-name $APP_NAME \
        --deployment-config-name CodeDeployDefault.OneAtATime \
        --deployment-group-name $DEPLOYMENT_NAME \
        --ec2-tag-filters Key=Name,Value=$APP_NAME,Type=KEY_AND_VALUE \
        --service-role-arn $ROLE_ARN \
        --auto-rollback-configuration file://assets/auto_rollback_enable.json \
        --deployment-style file://assets/deployment_style.json
        #--auto-scaling-groups $AUTO_SCALING_GROUPS \
        #--load-balancer-info $LOAD_BALANCER_INFO
fi

exit 0