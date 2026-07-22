###############################################################################
# EKS CLUSTER
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  endpoint_public_access = true

  # Ensure OIDC is created for general IRSA backwards compatibility
  enable_irsa = true

  compute_config = {
    enabled = false
  }

  # Managed Core Addons (EBS CSI driver moved below to use Pod Identity)
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  # ---------------------------------------------------------------------------
  # BASE MANAGED NODE GROUP (System Workloads & Addons)
  # ---------------------------------------------------------------------------
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

      # Permissions for SSM Management and ECR Image pulls
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        ECRPublicReadOnly            = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
      }

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

  # ---------------------------------------------------------------------------
  # CLUSTER ACCESS ENTRIES (AWS SSO + GitHub Actions CI/CD)
  # ---------------------------------------------------------------------------
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # 1. Human SSO Admin Access
    sso_console_admin = {
      principal_arn = "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps-AdministratorAccess_a8154c80336f8ef7"
      type          = "STANDARD"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # 2. Machine CI/CD Access (GitHub Actions OIDC Role)
    github_actions_cicd = {
      principal_arn = "arn:aws:iam::272495906318:role/github-actions-eks-deployer-role"
      type          = "STANDARD"

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

  # ---------------------------------------------------------------------------
  # ENCRYPTION & SECURITY GROUPS
  # ---------------------------------------------------------------------------
  create_kms_key = true

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

###############################################################################
# EBS CSI POD IDENTITY ROLE & ADDON
###############################################################################
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.10"

  name = "${var.cluster_name}-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [module.eks.kms_key_arn]

  associations = {
    main = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

# Dedicated addon resource so it waits for nodes and Pod Identity IAM
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  depends_on = [
    module.ebs_csi_pod_identity,
    module.eks.eks_managed_node_groups
  ]
}

###############################################################################
# DEFAULT STORAGE CLASS (gp3)
###############################################################################
resource "kubectl_manifest" "ebs_csi_default_storage_class" {
  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: gp3-default
    annotations:
      storageclass.kubernetes.io/is-default-class: "true"
  provisioner: ebs.csi.aws.com
  reclaimPolicy: Delete
  volumeBindingMode: WaitForFirstConsumer
  allowVolumeExpansion: true
  parameters:
    type: gp3  
    fsType: ext4
    encrypted: "true"
  YAML

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}

###############################################################################
# KARPENTER IAM ROLE & POD IDENTITY
###############################################################################
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.15.1"

  cluster_name = module.eks.cluster_name

  # Enable EKS Pod Identity association
  create_pod_identity_association = true

  # Attach required worker policies to the Karpenter node role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ECRPublicReadOnly            = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
  }

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

###############################################################################
# KARPENTER HELM RELEASE
###############################################################################
resource "helm_release" "karpenter" {
  namespace        = "kube-system"
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.0"
  create_namespace = false

  wait            = true
  cleanup_on_fail = true

  values = [
    <<-EOT
    replicas: 1
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]

  depends_on = [
    module.eks.eks_managed_node_groups
  ]
}

###############################################################################
# KARPENTER NODE CLASS (karpenter.k8s.aws/v1)
###############################################################################
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      amiSelectorTerms:
        - alias: al2023@latest
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: ${var.volume_size}Gi
            volumeType: ${var.volume_type}
            encrypted: true
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

###############################################################################
# KARPENTER NODE POOL (karpenter.sh/v1)
###############################################################################
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["4", "8", "16", "32"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

###############################################################################
# METRICS SERVER
###############################################################################
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.13.0"

  values = [
    file("${path.module}/metrics-values.yaml")
  ]

  depends_on = [
    module.eks
  ]
}