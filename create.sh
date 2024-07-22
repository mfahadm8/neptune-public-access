#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Custom error handler
function error_exit {
    echo "$1" 1>&2
    # Remove the zip file if it exists
    [ -f "$ZIP_FILE" ] && rm -f "$ZIP_FILE"
    exit 1
}

# Check if the required arguments are provided
if [ "$#" -ne 3 ]; then
    error_exit "Usage: $0 <lambda-function-name> <add-vpc> <neptune-db-cluster>"
fi

LAMBDA_FUNCTION_NAME=$1
ADD_VPC=$2
NEPTUNE_DB_CLUSTER=$3

# Step 1: Retrieve the VPC ID and Subnet IDs from the Neptune cluster if ADD_VPC is true
if [ "$ADD_VPC" == "true" ]; then
    NEPTUNE_CLUSTER_INFO=$(aws neptune describe-db-clusters --db-cluster-identifier $NEPTUNE_DB_CLUSTER) || error_exit "Failed to retrieve Neptune cluster info"
    INSTANCE_ID=$(echo $NEPTUNE_CLUSTER_INFO | perl -nle 'print $& if m{"DBInstanceIdentifier": "\K[^"]+}' | head -n 1) || error_exit "Failed to extract DBInstanceIdentifier"
    VPC_ID=$(aws neptune describe-db-instances --db-instance-identifier $INSTANCE_ID | perl -nle 'print $& if m{"VpcId": "\K[^"]+}') || error_exit "Failed to retrieve VPC ID"
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text | tr '\n' ' ') || error_exit "Failed to retrieve Subnet IDs"

    SUBNET_ID_ARRAY=($SUBNET_IDS)
    if [ ${#SUBNET_ID_ARRAY[@]} -lt 2 ]; then
        error_exit "Not enough subnets found in the VPC"
    fi

    echo "Retrieved VPC ID: $VPC_ID"
    echo "Retrieved Subnet IDs: ${SUBNET_ID_ARRAY[@]}"
else
    VPC_ID="dummy-vpc-id"
    SUBNET_ID_ARRAY=("dummy-subnet-id1" "dummy-subnet-id2")
fi

# Step 2: Retrieve the Neptune cluster endpoint
NEPTUNE_ENDPOINT=$(aws neptune describe-db-clusters --db-cluster-identifier $NEPTUNE_DB_CLUSTER --query "DBClusters[0].Endpoint" --output text) || error_exit "Failed to retrieve Neptune endpoint"

echo "Retrieved Neptune Endpoint: $NEPTUNE_ENDPOINT"

# Step 3: Zip the Lambda function code
ZIP_FILE="$LAMBDA_FUNCTION_NAME.zip"
cd $LAMBDA_FUNCTION_NAME/src || error_exit "Failed to navigate to the Lambda function directory"
zip -r ../../$ZIP_FILE . || error_exit "Failed to zip the Lambda function code"
cd ../..

echo "Zipped Lambda function code: $ZIP_FILE"

# Step 4: Upload the zip file to S3
S3_BUCKET="aws-sam-cli-managed-default-samclisourcebucket-wsvnc3lqfl9i"
aws s3 cp $ZIP_FILE s3://$S3_BUCKET/ || error_exit "Failed to upload zip file to S3"
S3_KEY="$LAMBDA_FUNCTION_NAME.zip"

echo "Uploaded Lambda function code to S3: s3://$S3_BUCKET/$S3_KEY"

# Step 5: Deploy the CloudFormation stack
STACK_NAME="${LAMBDA_FUNCTION_NAME}-stack"

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file template.yaml \
    --parameter-overrides FunctionName=$LAMBDA_FUNCTION_NAME VpcId=$VPC_ID SubnetIds=${SUBNET_ID_ARRAY[0]},${SUBNET_ID_ARRAY[1]} NeptuneEndpoint=$NEPTUNE_ENDPOINT AddVpc=$ADD_VPC CodeBucket=$S3_BUCKET CodeKey=$S3_KEY \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset || error_exit "Failed to deploy CloudFormation stack"

# Clean up the zip file after successful deployment
rm -f "$ZIP_FILE"
echo "CloudFormation stack creation initiated for Lambda function and other resources"
