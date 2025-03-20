# Helm provider
provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
     token                  = var.eks_token != "" ? var.eks_token : ""
  }
}
