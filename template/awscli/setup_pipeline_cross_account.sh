#!/bin/bash

#####################################################
# Setup Local Environment
#####################################################
if [ ! -d ".config" ]; then
    mkdir .config
fi

GIT="$(git --version 2> /dev/null | awk '{print $1}')"
PYTHON="$(python3 --version 2> /dev/null | awk '{print $1}')"
PIP="$(pip3 --version 2> /dev/null | awk '{print $1}')"
CURL="$(curl --version 2> /dev/null | awk '{print $1}' | cut -d ' ' -f 1 | head -1 )"
AWS_CLI="$(aws --version 2> /dev/null | awk '{print $1}' | cut -d '/' -f 1 )"
JQ="$(jq --version 2> /dev/null | awk '{print $1}' | cut -d '-' -f 1)"

if [ -z "$GIT" ] || [ -z "$PYTHON" ] || [ -z "$PIP" ] || [ -z "$CURL" ] || [ -z "$AWS_CLI" ] || [ -z "$JQ" ]; then
    # Required tools are not installed
    ./setup_local_envs
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

# set PROFILE_NAME
echo 'Please enter a cross account profile name.'
read LINE
PROFILE_NAME="$(echo $LINE)"
if [ -z "$PROFILE_NAME" ]; then
    DEFAULT_PROFILE_NAME='deployer'
    echo "$DEFAULT_PROFILE_NAME" will be set as profile name.
    PROFILE_NAME=DEFAULT_PROFILE_NAME
fi

# Setup Cross Account Environment
./setup_aws_configure_with_profile "$PROFILE_NAME"
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

# Set project description
echo 'Please enter a application name. If you do not enter a value, the repository name is the default.'
read LINE
APP_NAME="$(echo $LINE)"
if [ -z "$APP_NAME" ]; then
    APP_NAME=$REPOSITORY_NAME
fi
if [ 'master' != "$REPOSITORY_BRANCH" ]; then
    APP_NAME=$APP_NAME-$REPOSITORY_BRANCH
fi
unset LINE

DEPLOYMENT_GROUP=$APP_NAME-deploy-group
DEPLOY_FLATFORM='Server'

# Set pipeline information
PIPELINE_NAME=$REPOSITORY_NAME-pipeline
if [ 'master' != "$REPOSITORY_BRANCH" ]; then
    PIPELINE_NAME=$REPOSITORY_NAME-$REPOSITORY_BRANCH-pipeline
fi

# Set project description
echo 'Please enter a vpc id and subnet id and security group id for the codebuild configuration.' 
echo 'If you do not enter some of them, the default vpc is set by default.'
echo 'See the following links for vpc conditions'
echo 'https://docs.aws.amazon.com/codebuild/latest/userguide/vpc-support.html'
echo 'Please enter a vpc id.' 
read LINE
VPC_ID="$(echo $LINE)"
unset LINE
if [ -n "$VPC_ID" ]; then
    echo 'Please enter a subnet id.' 
    read LINE
    SUBNET_ID="$(echo $LINE)"
    unset LINE
    
    if [ -n "$SUBNET_ID" ]; then
        echo 'Please enter a security group id.' 
        read LINE
        SG_ID="$(echo $LINE)"
        unset LINE
    fi

fi

if [[ (-z "$VPC_ID") || (-z "$SUBNET_ID") || (-z "$SG_ID") ]]; then
    unset $VPC_ID
    unset $SUBNET_ID
    unset $SG_ID
fi
#####################################################
# Generate Repository
#####################################################
./generate_codecommit \
    --name "$REPOSITORY_NAME" \
    --description "$REPOSITORY_DESCRIPTION" \
    --target-url "$TARGET_URL"
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
# Create KMS key for cross account
#####################################################
./create_custom_key_cross_account \
    --name "$PIPELINE_NAME" \
    --cross-account-profile "$PROFILE_NAME"
if [ 0 -ne $? ]; then
    echo 'Customer key creation failed'
    exit 9
fi

#####################################################
# Setup Builder Environment
#####################################################
./generate_codebuild \
    --name "$BUILD_PROJECT_NAME" \
    --description "$BUILD_DESCRIPTION" \
    --s3-bucket "$S3_BUCKET" \
    --type "CODEPIPELINE" \
    --s3-kms-key-alias "CrossAccountKeyfor-$REGION-$PIPELINE_NAME" \
    --vpc-id "$VPC_ID" \
    --subnet-id "$SUBNET_ID" \
    --security-group-id "$SG_ID"
if [ 0 -ne $? ]; then
    echo 'CodeBuild creation failed'
    exit 9
fi

#####################################################
# Setup Deploy Environment
#####################################################
./generate_codedeploy_cross_account \
    --name "$APP_NAME" \
    --deployment-name "$DEPLOYMENT_GROUP" \
    --platform "$DEPLOY_FLATFORM" \
    --cross-account-profile "$PROFILE_NAME"
if [ 0 -ne $? ]; then
    echo 'CodeDeploy creation failed'
    exit 9
fi

#####################################################
# Setup Pipeline
#####################################################
./generate_codepipeline_cross_account \
    --name "$PIPELINE_NAME" \
    --s3-bucket "$S3_BUCKET" \
    --repository-name "$REPOSITORY_NAME" \
    --branch "$REPOSITORY_BRANCH" \
    --build-project-name "$BUILD_PROJECT_NAME" \
    --application-name "$APP_NAME" \
    --deployment-group-name "$DEPLOYMENT_GROUP" \
    --cross-account-profile $PROFILE_NAME
if [ 0 -ne $? ]; then
    echo 'CodePipeline creation failed'
    exit 9
fi