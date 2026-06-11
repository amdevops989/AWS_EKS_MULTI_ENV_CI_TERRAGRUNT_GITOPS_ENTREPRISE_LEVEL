# Get the EKS node security group
data "aws_security_group" "eks_node_group" {
  tags = {
    Name = "${var.cluster_name}-node"   ## make it variable from output
  }
}

# data "aws_security_group" "eks_cluster" {
#   tags = {
#     Name = "${var.cluster_name}-cluster"  ##make it variable from output
#   }
# }


# Istiod XDS + webhook (15010-15017)
resource "aws_security_group_rule" "istio_pilot" {
  type              = "ingress"
  from_port         = 15010
  to_port           = 15017
  protocol          = "tcp"
  self              = true
  security_group_id = data.aws_security_group.eks_node_group.id
  description       = "Istiod discovery / webhook communication"
}

# Envoy inbound sidecar communication (15001)
resource "aws_security_group_rule" "istio_sidecar" {
  type              = "ingress"
  from_port         = 15001
  to_port           = 15001
  protocol          = "tcp"
  self              = true
  security_group_id = data.aws_security_group.eks_node_group.id
  description       = "Envoy sidecar inbound traffic"
}

# Envoy admin port (15000)
resource "aws_security_group_rule" "istio_envoy_admin" {
  type              = "ingress"
  from_port         = 15000
  to_port           = 15000
  protocol          = "tcp"
  self              = true
  security_group_id = data.aws_security_group.eks_node_group.id
  description       = "Envoy admin port"
}

# Optional: Istiod metrics (15014)
resource "aws_security_group_rule" "istio_metrics" {
  type              = "ingress"
  from_port         = 15014
  to_port           = 15014
  protocol          = "tcp"
  self              = true
  security_group_id = data.aws_security_group.eks_node_group.id
  description       = "Istiod metrics for Prometheus scraping"
}


resource "aws_security_group_rule" "istio_webhook_from_cp" {
  type                     = "ingress"
  from_port                = 15017
  to_port                  = 15017
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.eks_node_group.id
  source_security_group_id = var.cluster_security_group_id
  description              = "Allow EKS control plane to reach Istiod webhook"
}