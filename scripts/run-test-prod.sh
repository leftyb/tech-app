#!/bin/bash

CURRENT_PATH=$(pwd)

if [ "$ENV" = "dev" ]; then
   echo "Run tests for Dev"

    # Test the app
   python3 -m unittest discover -s test-app/ -p 'test_svc.py'
   
elif [ "$ENV" = "prod" ]; then
    echo "Run tests for Prod"
    if [[ -z "$GITHUB_ACTIONS" ]]; then
        source "${CURRENT_PATH}/aws_credentials.sh"
    fi

    # Set KUBECONFIG dynamically, generated from EKS.
    export KUBECONFIG="${CURRENT_PATH}/infra/app-infra/kubeconfig"

    #Run tests
    python3 -m unittest discover -s "${CURRENT_PATH}/test-app/" -p 'test_*.py'

else
  echo "Please set ENV=dev or ENV=prod to create the corresponding environment \
  For more details, check the README.md file"
fi