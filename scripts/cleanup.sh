#!/bin/bash

# Initialize environment variable (defaults to 'none' if not set)
export ENV=${ENV:-none}
CURRENT_PATH=$(pwd)

AUTO_APPROVE_FLAG=""
if [[ "${TF_AUTO_APPROVE}" == "true" ]]; then
    AUTO_APPROVE_FLAG="-auto-approve"
    echo "Terraform auto-approve enabled"
else
    echo "Terraform auto-approve disabled"
fi

# Set up environment based on the value of ENV
if [ "$ENV" = "dev" ]; then
  echo "Clean up Dev environment..."

  # Delete Kind cluster for dev environment
  kind delete clusters dev-cluster 
    if [ $? -ne 0 ]; then
    echo "Error: Failed to delete kind cluster."
  fi 
  
elif [ "$ENV" = "prod" ]; then
  echo "Clean up Prod environment..."
 
  source "${CURRENT_PATH}/aws_credentials.sh"
  export KUBECONFIG="${CURRENT_PATH}/infra/app-infra/kubeconfig"

  # Delete the APP Resources
   kubectl delete -f "${CURRENT_PATH}/app-manifests" --grace-period=0 --force
   if [ $? -ne 0 ]; then
    echo "Error: Failed to delete the manifests."
   fi

  while kubectl get all --all-namespaces -l app=message-api | grep -q message-api; do
    echo "Waiting for resources to be deleted..."
    sleep 5
  done
    echo "All 'message-api' resources are deleted."
  
  cd "${CURRENT_PATH}/infra/app-infra"
  
  # Destroy EKS resources.
  terraform destroy ${AUTO_APPROVE_FLAG}
  
  cd "${CURRENT_PATH}/infra/state-infra"

  #Empty & delete state s3 bucket
  # Delete all object versions
  aws s3api delete-objects --bucket tech-app-state-bucket --delete "$(aws s3api list-object-versions --bucket tech-app-state-bucket --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" >/dev/null 2>&1

  # Delete all delete markers
  aws s3api delete-objects --bucket tech-app-state-bucket --delete "$(aws s3api list-object-versions --bucket tech-app-state-bucket --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" >/dev/null 2>&1

  # Remove the bucket
  aws s3 rb s3://tech-app-state-bucket --force >/dev/null 2>&1
 
  echo "All resources destroyed "

else
  echo "Please set ENV=dev or ENV=prod to cleanup \
  For more details, check the README.md file"
fi
