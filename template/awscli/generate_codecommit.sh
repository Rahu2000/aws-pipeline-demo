#!/bin/bash

# set REPOSITORY_NAME
while :
do
    echo 'Input REPOSITORY_NAME:'
    read LINE
    REPOSITORY_NAME="$(echo $LINE)"
    if [ -z "$REPOSITORY_NAME" ]; then
        echo 'Invalid data'
    else
        break
    fi
done
unset LINE

# set REPOSITORY_DESCRIPTION
while :
do
    echo 'Input REPOSITORY_DESCRIPTION:'
    read LINE
    REPOSITORY_DESCRIPTION="$(echo $LINE)"
    if [ -z "$REPOSITORY_DESCRIPTION" ]; then
        echo 'Invalid data'
    else
        break
    fi
done
unset LINE

# Generate AWS CodeCommit Repository
REPO_URL="$(aws codecommit create-repository --repository-name $REPOSITORY_NAME --repository-description "$REPOSITORY_DESCRIPTION" | jq .repositoryMetadata.cloneUrlHttp | tr -d \")"

echo $REPO_URL

# Initial Repository
# git clone --mirror $TEMPLATE_GIT_URL temprepo
# cd temprepo
# git push $REPO_URL --all

#echo MyDemoRepo >> README.md
#git init
#git add README.md
#git commit -m "Generate MyDemoRepo Project Pipeline" 
#git push $REPO_URL master

exit 0