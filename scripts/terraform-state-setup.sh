#!/bin/bash

cd  $(pwd)/infra/state-infra
BUCKET="tech-app-state-bucket"
SERVICE_NAME="tech-app/state.tfstate"

# Function to initialize Terraform with S3 backend
terraform_init_remote() {
    echo "Initializing Terraform with remote backend"

    terraform init -reconfigure \
        -backend-config="bucket=${BUCKET}" \
        -backend-config="key=${SERVICE_NAME}" \
        -backend-config="encrypt=true"

    if [ $? -eq 0 ]; then
        echo "Terraform initialization successful!"
    else
        echo "Terraform initialization failed!"
        exit 1
    fi
}

if aws s3api head-bucket --bucket "${BUCKET}"  >/dev/null 2>&1; then
    echo "S3 bucket exists: ${BUCKET}"
else
  aws s3api create-bucket --bucket ${BUCKET} --region ${AWS_DEFAULT_REGION} --create-bucket-configuration LocationConstraint=${AWS_DEFAULT_REGION} >/dev/null 2>&1    
  # Check if the bucket was created successfully (exit code 0 means success)
  if [ $? -eq 0 ]; then
    echo "Bucket ${BUCKET} created successfully."
  else
    echo "Failed to create bucket ${BUCKET}."
    exit 1
  fi
fi

#Check if the state file exists in S3
if aws s3 ls "s3://${BUCKET}/${SERVICE_NAME}" >/dev/null 2>&1; then
  echo "Terraform state file already exist"
  terraform_init_remote
else  
  terraform_init_remote
  terraform import module.s3bucket.aws_s3_bucket.tfstate_bucket ${BUCKET}
fi

# Plan the production deployment
terraform plan
if [ $? -ne 0 ]; then
  echo "Terraform plan failed"
  exit 1  
fi

# Apply the production deployment
terraform apply ${AUTO_APPROVE_FLAG}
if [ $? -ne 0 ]; then
    echo "Terraform apply was rejected or failed. Exiting script..."
    exit 1  
fi

#Check if the state file exists in S3
if aws s3 ls "s3://${BUCKET}/${SERVICE_NAME}" >/dev/null 2>&1; then
    echo "Terraform state file exist"
else
    echo "Terraform state file NOT exist"
    exit 1 
fi





