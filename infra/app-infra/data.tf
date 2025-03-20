#Passed to karpenter module
data "aws_eks_cluster_auth" "eks" {
  name = module.eks-infra.eks_cluster_name
}