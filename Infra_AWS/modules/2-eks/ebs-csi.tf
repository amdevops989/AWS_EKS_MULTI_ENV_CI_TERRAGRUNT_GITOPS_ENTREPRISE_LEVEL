###############################################################################
# EBS CSI
###############################################################################
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name = "${var.cluster_name}-ebs-csi"

  attach_ebs_csi_policy = true
#   ebs_csi_kms_cmk_ids   = [module.kms.key_arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = "1.33"
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = data.aws_eks_addon_version.ebs_csi.version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

###############################################################################
# Storage Class
###############################################################################
resource "kubectl_manifest" "ebs_csi_default_storage_class" {
  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    annotations:
      storageclass.kubernetes.io/is-default-class: "true"
    name: gp3-default
  provisioner: ebs.csi.aws.com
  reclaimPolicy: Delete
  volumeBindingMode: WaitForFirstConsumer
  allowVolumeExpansion: true
  parameters:
    type: gp3  
    fsType: ext4
    encrypted: "true"
    # kmsKeyId: ""  ## in case of foreign cmk
  YAML
}