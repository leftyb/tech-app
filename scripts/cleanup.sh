#!/bin/bash

# Initialize environment variable (defaults to 'dev' if not set)
echo "ENV is: ${ENV}"
export ENV=${ENV:-none}
CURRENT_PATH=$(pwd)

AUTO_APPROVE_FLAG=""
if [[ "${TF_AUTO_APPROVE}" == "true" ]]; then
    AUTO_APPROVE_FLAG="-auto-approve"
    echo "Terraform auto-approve enabled"
else
    echo "Terraform auto-approve disabled"
fi

execute_with_wait() {
    local message="$1"
    local timeout="$2"
    local command="$3"
    local elapsed_time=0

    echo -n "$message"

    while [ "$elapsed_time" -lt "$timeout" ]; do
        echo -n "."
        sleep 5
        elapsed_time=$((elapsed_time + 5))

        # Execute the command and chek if success
        if "$command" >/dev/null 2>&1; then
            break
        fi
    done

    echo ""  
    "$command"  # Run the function one last time to show output
}

check_worker_nodes() {
    WORKER_NODES=$(kubectl get nodes --no-headers | awk '!/fargate/ {print $1}')

    if [ -z "$WORKER_NODES" ]; then
        echo "All worker nodes have been removed!"
        return 0
    else
        return 1  #nodes are still present
    fi
}

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
 
  if [[ -z "$GITHUB_ACTIONS" ]]; then
    source "${CURRENT_PATH}/aws_credentials.sh"
  fi  
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
    echo "All resources are deleted."

  if kubectl get ns argocd > /dev/null 2>&1; then
    echo "ArgoCD is installed. Force deleting all resources"

    kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --grace-period=0 --force

    # Delete all ArgoCD CRDs
    echo "Deleting ArgoCD Custom Resource Definitions (CRDs)..."
    kubectl delete crd applications.argoproj.io appprojects.argoproj.io argocds.argoproj.io --ignore-not-found

    # Force delete the ArgoCD namespace
    echo "Deleting the ArgoCD namespace..."
    kubectl delete namespace argocd --grace-period=0 --force

    echo "ArgoCD has been completely removed."
  else
    echo "ArgoCD is not installed."
  fi
  
  #Delete nodepool to delete all nodes.
  kubectl delete nodepool --all

  #wait not fargate nodes to be removed.
  execute_with_wait "Checking for removed worker nodes" 120 check_worker_nodes
  
  cd "${CURRENT_PATH}/infra/app-infra"
  
  terraform init
  if [ $? -ne 0 ]; then
    echo "Terraform init failed"
    exit 1  
  fi

  # Destroy EKS resources.
  terraform destroy ${AUTO_APPROVE_FLAG}
  if [ $? -ne 0 ]; then
    echo "Terraform destroy failed"
    exit 1  
  fi

  #Empty & delete state s3 bucket
  # Delete all object versions
  aws s3api delete-objects --bucket tech-app-state-bucket --delete "$(aws s3api list-object-versions --bucket tech-app-state-bucket --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" >/dev/null 2>&1

  # Delete all delete markers
  aws s3api delete-objects --bucket tech-app-state-bucket --delete "$(aws s3api list-object-versions --bucket tech-app-state-bucket --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" >/dev/null 2>&1

  # Remove the bucket
  aws s3 rb s3://tech-app-state-bucket --force >/dev/null 2>&1
  
  rm ${CURRENT_PATH}/infra/app-infra/kubeconfig

  echo "All resources destroyed"

else
  echo "Please set ENV=dev or ENV=prod to cleanup."
  echo "For more details, check the README.md file."
fi
