###############################################################################
# EKS
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name    = var.cluster_name
  kubernetes_version = var.cluster_version

  endpoint_public_access  = true

  compute_config = {
   enabled = false
  }

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_type
      labels = {
        workload = "addons"
        role     = "main"
      }

      min_size     = var.node_min_capacity
      max_size     = var.node_max_capacity
      desired_size = var.node_desired_capacity

      # --- FIX: Add public ECR permissions to this node group ---
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        ECRPublicReadOnly            = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
      }
      # ----------------------------------------------------------

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.volume_size
            volume_type           = var.volume_type
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true

  # --- ADD THIS BLOCK TO MAP YOUR AWS SSO ADMINISTRATOR ACCESS ROLE ---
  access_entries = {
    console_admin = {
      # Updated with your exact active SSO Role ARN from the dropdown
      principal_arn     = "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSAdministratorAccess_58741448858b49f4"
      type              = "STANDARD"
      
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  # --------------------------------------------------------------------

  create_kms_key = false
  encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/eks"
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}