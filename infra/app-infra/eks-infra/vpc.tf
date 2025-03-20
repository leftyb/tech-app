################################################################################
# VPC

locals {
  name   = "eks-tech-app"
  region = var.region

  vpc_cidr = "10.0.0.0/24"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    name    = local.name
  }
}

data "aws_availability_zones" "available" {
  # Exclude opt-in zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs  = local.azs
  # Private subnets with /28 (16 IPs per subnet)
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k )]
  # Public subnets with /28 (16 IPs per subnet)
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 3)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

 private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.name
  }

  tags = local.tags
}