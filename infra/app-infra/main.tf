module "eks-infra" {
  source = "./eks-infra"
}

module "karpenter" {
  source     = "./karpenter"
  
  eks_cluster_name                          = module.eks-infra.eks_cluster_name
  eks_cluster_endpoint                      = module.eks-infra.eks_cluster_endpoint
  eks_cluster_certificate_authority_data    = module.eks-infra.eks_cluster_certificate_authority_data
  eks_cluster_oidc_provider_arn             = module.eks-infra.eks_cluster_oidc_provider_arn  
  eks_token                                 = module.eks-infra.eks_cluster_endpoint != "" ? data.aws_eks_cluster_auth.eks.token : "" 
}