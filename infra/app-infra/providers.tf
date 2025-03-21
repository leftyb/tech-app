#manage state file
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90" 
    }
  }

  # Remote S3 bucket backend
  backend "s3" {
    bucket = "tech-app-state-bucket"    
    key    = "tech-app/terraform.tfstate"  
    encrypt = true                           
  }
}
