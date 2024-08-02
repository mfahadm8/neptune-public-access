#!/bin/bash
# Custom error handler
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Check if the required argument is provided
if [ "$#" -lt 1 ] || [ "$#" -gt 1 ]; then
    error_exit "Usage: $0 <FunctionName>"
fi

LAMBDA_FUNCTION_NAME=$1

STACK_NAME="${LAMBDA_FUNCTION_NAME}-stack"
echo "Deleting CloudFormation stack: $STACK_NAME"
aws cloudformation delete-stack --stack-name $STACK_NAME || error_exit "Failed to delete CloudFormation stack"
