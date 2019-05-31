#!/bin/bash
unset S3_BUCKET
S3_BUCKET="$1"

if [ -z "$S3_BUCKET" ]; then
    S3_BUCKET="codepipeline-$(aws configure get region)-$(uuidgen | cut -d '-' -f 5)"
fi

# Generate S3 Bucket
if [ -z "$(aws s3 ls | grep $S3_BUCKET)" ]; then
    S3_BUCKET="$(aws s3 mb "s3://$S3_BUCKET" | cut -d ' ' -f 2)"
    
    # Set codepipeline policy to s3 Bucket
    cat policies/S3BucketPolicy.json | sed "s/S3-BUCKET-NAME/$S3_BUCKET/g" > .config/"$S3_BUCKET".json
    aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file://.config/"$S3_BUCKET".json
else
    echo $S3_BUCKET is already exist
fi

exit 0