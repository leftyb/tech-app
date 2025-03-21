################################################################################
# EKS Cluster

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.34"

  cluster_name    = local.name
  cluster_version = "1.30"

  # Give the Terraform identity admin access to the cluster
  # which will allow it to deploy resources into the cluster
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  cluster_addons = {
    # Enable after creation to run on Karpenter managed nodes
    # coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Fargate profiles use the cluster primary security group
  # Therefore these are not used and can be skipped
  create_cluster_security_group = false
  create_node_security_group    = false

  fargate_profiles = {
   karpenter = {
     selectors = [
       { namespace = "karpenter" }
     ]
   },
   kube_system = {
     selectors = [
       { namespace = "kube-system" }
     ]
   }
  }


  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })

  # First create the VPC.
  depends_on = [module.vpc]
}

resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --kubeconfig ./kubeconfig"
  }

  depends_on = [module.eks]  # Ensure this runs after the EKS module is created
}