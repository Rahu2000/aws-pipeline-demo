#!/bin/bash

#####################################################
# Setup Local Environment
#####################################################
GIT="$(git --version 2> /dev/null | awk '{print $1}')"
PYTHON="$(python3 --version 2> /dev/null | awk '{print $1}')"
PIP="$(pip3 --version 2> /dev/null | awk '{print $1}')"
CURL="$(curl --version 2> /dev/null | awk '{print $1}' | cut -d ' ' -f 1 | head -1 )"
AWS_CLI="$(aws --version 2> /dev/null | awk '{print $1}' | cut -d '/' -f 1 )"
JQ="$(jq --version 2> /dev/null | awk '{print $1}' | cut -d '-' -f 1)"

if [ -z $GIT ] | [ -z $PYTHON ] | [ -z $PIP ] | [ -z $CURL ] | [ -z $AWS_CLI ] | [ -z $JQ ]; then
    # Required tools are not installed
    ./local_env
    if [ 0 -ne $? ]; then
        echo 'Local environment setup is failed.'
        exit 9
    fi
fi

# Setup AWS Environment
./setup_aws_configure
if [ 0 -ne $? ]; then
    echo 'AWS-CLI setup is failed.'
    exit 9
fi

# Setup Git Environment
./setup_git_configure
if [ 0 -ne $? ]; then
    echo 'Git setup is failed.'
    exit 9
fi

#####################################################
# Get Pipeline values
#####################################################
REGION="$(aws configure get region)"
unset S3_BUCKET
unset REPOSITORY_BRANCH

# Set project Name
echo 'Please enter a project name.'
echo 'The project name is the base of the repository and pipeline.'
while :
do
    read LINE
    REPOSITORY_NAME="$(echo $LINE)"
    if [ -z "$REPOSITORY_NAME" ]; then
        echo 'The project name is required.'
    else
        break
    fi
done
unset LINE

# Set project description
echo 'Please enter a project description.'
read LINE
REPOSITORY_DESCRIPTION="$(echo $LINE)"
if [ -z "$REPOSITORY_DESCRIPTION" ]; then
    REPOSITORY_DESCRIPTION=$REPOSITORY_NAME
fi
unset LINE

# Set template git url
echo 'If there is a clone git URL, enter it.'
read LINE
TARGET_URL="$(echo $LINE)"
unset LINE

# Set S3 bucket
echo 'Would you want to create an S3 bucket for pipeline? Y or N'
read LINE
if [ 'Y' == "$LINE" ] | [ 'y' == "$LINE" ]; then
    echo "New S3 bucket for pipeline will be created."
else
    echo 'Enter an existing S3 location from your account in the same region and account as your pipeline.'
    read S3_BUCKET
    if [ -z "$(aws s3 ls --region $REGION | grep $S3_BUCKET)" ]; then
        echo "$S3_BUCKET is not exist."
        echo "New S3 bucket will for pipeline be created."
        unset S3_BUCKET
    fi
fi
unset LINE

# Set default branch
if [ -z $REPOSITORY_BRANCH ]; then
    REPOSITORY_BRANCH='master'
fi

# Set build information
BUILD_PROJECT_NAME=$REPOSITORY_NAME-build
if [ 'master' != "$REPOSITORY_BRANCH" ]; then
    BUILD_PROJECT_NAME=$REPOSITORY_NAME-$REPOSITORY_BRANCH-build
fi
BUILD_DESCRIPTION="The builder of the $REPOSITORY_NAME by the AWS CodeBuild."

# Set deploy information
APP_NAME=$REPOSITORY_NAME
if [ 'master' != "$REPOSITORY_BRANCH" ]; then
    APP_NAME=$REPOSITORY_NAME-$REPOSITORY_BRANCH
fi
DEPLOYMENT_GROUP=$APP_NAME-deploy-group
DEPLOY_FLATFORM='Server'

# Set pipeline information
PIPELINE_NAME=$REPOSITORY_NAME-pipeline
if [ 'master' != "$REPOSITORY_BRANCH" ]; then
    PIPELINE_NAME=$REPOSITORY_NAME-$REPOSITORY_BRANCH-pipeline
fi

#####################################################
# Create application resource
#####################################################
if [ 'Server' == "$DEPLOY_FLATFORM" ]; then
    ./generate_ec2 -n $APP_NAME
    if [ 0 -ne $? ]; then
        echo 'EC2 failed to start'
        exit 9
    fi
fi

#####################################################
# Generate Repository
#####################################################
./generate_codecommit -n "$REPOSITORY_NAME" -d "$REPOSITORY_DESCRIPTION" -t "$TARGET_URL"
if [ 0 -ne $? ]; then
    echo 'Repository creation failed'
    exit 9
fi

#####################################################
# Generate S3 Bucket
#####################################################
if [ -z "$S3_BUCKET" ]; then
    S3_BUCKET="codepipeline-$REGION-$(uuidgen | cut -d '-' -f 5)"
    ./generate_s3_bucket $S3_BUCKET
    if [ 0 -ne $? ]; then
        echo 'S3 bucket creation failed'
        exit 9
    fi
fi

#####################################################
# Setup Builder Environment
#####################################################
./generate_codebuild -n "$BUILD_PROJECT_NAME" -d "$BUILD_DESCRIPTION" -s "$S3_BUCKET" -t "CODEPIPELINE"
if [ 0 -ne $? ]; then
    echo 'CodeBuild creation failed'
    exit 9
fi

#####################################################
# Setup Deploy Environment
#####################################################
./generate_codedeploy -n "$APP_NAME" -d "$DEPLOYMENT_GROUP" -p "$DEPLOY_FLATFORM"
if [ 0 -ne $? ]; then
    echo 'CodeDeploy creation failed'
    exit 9
fi

#####################################################
# Setup Pipeline
#####################################################
./generate_codepipeline -n "$PIPELINE_NAME" -s "$S3_BUCKET" -r "$REPOSITORY_NAME" -b "$REPOSITORY_BRANCH" -bp "$BUILD_PROJECT_NAME" -an "$APP_NAME" -dg "$DEPLOYMENT_GROUP"
if [ 0 -ne $? ]; then
    echo 'CodePipeline creation failed'
    exit 9
fi