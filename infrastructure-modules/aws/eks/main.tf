locals {
  tags = merge(var.tags, { Name = var.name, ManagedBy = "opentofu" })
}

# Envelope key for etcd secret encryption. Rotation is automatic; without this,
# Kubernetes Secrets sit in etcd protected only by disk encryption.
resource "aws_kms_key" "eks" {
  description             = "EKS secret envelope encryption for ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = local.tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks-${var.name}"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.eks.arn
  tags              = local.tags
}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.name}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ])

  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}

resource "aws_security_group" "cluster" {
  name        = "${var.name}-eks-cluster"
  description = "EKS control plane ENIs for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-eks-cluster" })

  lifecycle {
    create_before_destroy = true
  }
}

# Deny-all by default: the only rule is the control plane reaching node kubelets.
# Everything else is added by the consuming stack, explicitly.
resource "aws_vpc_security_group_egress_rule" "cluster_to_nodes" {
  security_group_id            = aws_security_group.cluster.id
  description                  = "Control plane to node kubelet and extension API servers"
  referenced_security_group_id = aws_security_group.nodes.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "nodes" {
  name        = "${var.name}-eks-nodes"
  description = "EKS worker nodes for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name                                = "${var.name}-eks-nodes"
    "kubernetes.io/cluster/${var.name}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_cluster" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Kubelet and extension API servers from the control plane"
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_nodes" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Pod-to-pod traffic between nodes"
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
}

# Nodes need outbound access to pull images and reach the EKS API. Restrict
# further with NetworkPolicy inside the cluster rather than here.
resource "aws_vpc_security_group_egress_rule" "nodes_egress" {
  security_group_id = aws_security_group.nodes.id
  description       = "Node egress for image pulls and AWS APIs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn
  tags     = local.tags

  enabled_cluster_log_types = var.enabled_log_types

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.endpoint_public_access_cidrs : null
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nodes" {
  name               = "${var.name}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

resource "aws_launch_template" "nodes" {
  for_each = var.node_groups

  name_prefix            = "${var.name}-${each.key}-"
  vpc_security_group_ids = [aws_security_group.nodes.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }

  # IMDSv2 only, hop limit 1 — blocks the SSRF-to-node-credentials path.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.name}-${each.key}" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  labels          = each.value.labels
  tags            = local.tags

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  launch_template {
    id      = aws_launch_template.nodes[each.key].id
    version = aws_launch_template.nodes[each.key].latest_version
  }

  update_config {
    max_unavailable_percentage = 33
  }

  dynamic "taint" {
    for_each = each.value.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  lifecycle {
    # Desired size drifts as the cluster autoscaler works; re-applying should not
    # snap it back and cause a mass reschedule.
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}

# Native NetworkPolicy enforcement via the VPC CNI's built-in eBPF policy
# agent (addon >= 1.14). Without this, every NetworkPolicy this platform
# renders — golden path Helm charts, infrastructure-modules/kubernetes/namespace's
# default-deny — is silently unenforced: the object applies successfully but
# does nothing. GKE enforces via Calico and AKS via Cilium; this is EKS's
# equivalent, kept as an AWS-managed addon rather than a self-operated CNI.
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = local.tags

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
  })
}

# IRSA: lets workloads assume IAM roles via ServiceAccount tokens instead of
# inheriting the node role.
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  tags            = local.tags
}
