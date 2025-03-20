#!/bin/bash

AUTO_APPROVE_FLAG=""
if [[ "${TF_AUTO_APPROVE}" == "true" ]]; then
    AUTO_APPROVE_FLAG="-auto-approve"
    echo "Terraform auto-approve enabled"
else
    echo "Terraform auto-approve disabled"
fi

#Function to execute kubectl validation command with timeout
execute_with_wait() {
    local message="$1"
    local timeout="$2"
    local command="$3"
    local elapsed_time=0

    echo -n "$message"

    while [ $elapsed_time -lt $timeout ]; do
        echo -n "."
        sleep 5
        elapsed_time=$((elapsed_time + 5))

        # Execute the command and check if it succeeds
        eval "$command" >/dev/null 2>&1 && break
    done

    echo "" 

    
    eval "$command"
    return $?  # Return the result of the command execution
}

# Initialize environment variable (defaults to 'dev' if not set)
export ENV=${ENV:-none}
CURRENT_PATH=$(pwd)

# Set up environment based on the value of ENV
if [ "$ENV" = "dev" ]; then
  echo "Setting up Dev environment..."

  # Create Kind cluster for dev environment
  kind create cluster --name dev-cluster

  # Set the current context to use the created Kind cluster
  kubectl config use-context kind-dev-cluster

  # Apply the manifests
  kubectl apply -f ./app-manifests
  if [ $? -ne 0 ]; then
    echo "Error: Failed to apply the manifests."
  fi

  # Wait for the deployment to become available
  kubectl wait --for=condition=available --timeout=60s deployment/message-api -n message-api
  if [ $? -ne 0 ]; then
    echo "Error: Deployment message-api did not become available within the timeout."
  fi

  echo "Deployment is available and ready!"

  # Test the app
  python3 -m unittest discover -s test-app/ -p 'test_svc.py'
  

elif [ "$ENV" = "prod" ]; then
   echo "Setting up Prod environment..."
      
   TIMEOUT=360  # Maximum wait time for app to be ready
   INTERVAL=5   # Interval in seconds
   SECONDS=0    # Built-in Bash variable that tracks elapsed seconds

   source "${CURRENT_PATH}/aws_credentials.sh"

   #Create S3 bucket to store terraform remote state.
   source "${CURRENT_PATH}/scripts/terraform-state-setup.sh"

   # Navigate to the production directory
   cd "${CURRENT_PATH}/infra/app-infra"
   
   # Initialize Terraform for the prod environment
   terraform init

   # Plan the production deployment
   terraform plan 

   # Apply the production deployment
   terraform apply ${AUTO_APPROVE_FLAG}
  
   # Set KUBECONFIG dynamically, generated from EKS.
   export KUBECONFIG="${CURRENT_PATH}/infra/app-infra/kubeconfig"
   
   # Rollout karpenter deployment to trigger the Fargate creation 
   kubectl rollout restart deployment karpenter -n karpenter

  # Wait for all karpenter pods to be ready
  execute_with_wait "Waiting for Karpenter pods to be ready for ${TIMEOUT} seconds" \
      $TIMEOUT \
      "kubectl get deployment karpenter -n karpenter -o jsonpath=\"{.status.conditions[?(@.type=='Available')].status}\" | grep -q True"

  # Check the status of karpenter PODS
  if [ $? -eq 0 ]; then
      echo "All Karpenter pods are now ready!"
  else
      echo " Error: Karpenter pods not become ready after ${TIMEOUT} seconds."
      exit 1
  fi   

   #Apply Karpenter config manifests
   kubectl apply -f "${CURRENT_PATH}/infra/app-infra/karpenter/karpenter.yaml"
   if [ $? -ne 0 ]; then
    echo "Error: Failed to apply the karpenter manifests."
    exit 1
   fi
   
   # Wait for all "kube-system" pods to be ready
   execute_with_wait "Waiting for 'kube-system' pods to be ready for ${TIMEOUT} seconds" \
      $TIMEOUT \
      "kubectl get pods -n kube-system -o jsonpath=\"{.items[*].status.conditions[?(@.type=='Ready')].status}\" | grep -qv False"

   # Check the status of "kube-system" PODS
   if [ $? -eq 0 ]; then
      echo "All "kube-system" pods are now ready!"
   else
      echo " Error: "kube-system" pods not become ready after ${TIMEOUT} seconds."
      exit 1
   fi  

   # Apply the manifests
   kubectl apply -f "${CURRENT_PATH}/app-manifests"
   if [ $? -ne 0 ]; then
    echo "Error: Failed to apply the manifests."
    exit 1
   fi

   # Wait for the deployment to become available
    execute_with_wait "Waiting for 'message-api' pods to be ready for ${TIMEOUT} seconds" \
      $TIMEOUT \
      "kubectl get deployment message-api -n message-api -o jsonpath=\"{.status.conditions[?(@.type=='Available')].status}\" | grep -q True"

   #Run tests
   python3 -m unittest discover -s "${CURRENT_PATH}/test-app/" -p 'test_*.py'

else
  echo "Please set ENV=dev or ENV=prod to create the corresponding environment \
  For more details, check the README.md file"
fi
