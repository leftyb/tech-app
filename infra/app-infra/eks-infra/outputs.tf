output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "kubeconfig_path" {
  description = "The path to the custom kubeconfig file for kubectl"
  value       = "./kubeconfig"
}