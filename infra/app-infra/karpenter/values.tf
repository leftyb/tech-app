#For eks-infra module

variable "eks_cluster_name" {
  type = string
}

variable "eks_cluster_endpoint" {
  type = string
}

variable "eks_cluster_certificate_authority_data" {
  type = string
}

variable "eks_cluster_oidc_provider_arn" {
  type = string
}

variable "eks_token" {}
