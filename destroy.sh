#!/bin/bash
STACK_NAME="NeptuneALBStack"
echo "Deleting CloudFormation stack: $STACK_NAME"
aws cloudformation delete-stack --stack-name $STACK_NAME || error_exit "Failed to delete CloudFormation stack"
