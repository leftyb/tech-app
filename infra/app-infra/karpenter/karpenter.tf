locals {
  namespace = "karpenter"
  name   = "eks-tech-app"
  tags = {
    name    = local.name
  }
}

#Provider to pull Karpenter Helm Chart
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# Data source to fetch the public ECR authorization token
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia # Use the virginia provider
}

################################################################################
# Karpenter module

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"

  cluster_name          = var.eks_cluster_name
  enable_v1_permissions = true
  namespace             = local.namespace

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = local.name

  # EKS Fargate does not support pod identity
  create_pod_identity_association = false
  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.eks_cluster_oidc_provider_arn
  tags = local.tags
}

################################################################################
# Helm chart for Karpentet

resource "helm_release" "karpenter" {
  provider            = helm
  name                = "karpenter"
  namespace           = local.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.3.3"
  wait                = false

  values = [
    <<-EOT
    dnsPolicy: Default
    settings:
      clusterName: ${var.eks_cluster_name}
      clusterEndpoint: ${var.eks_cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    webhook:
      enabled: true
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
