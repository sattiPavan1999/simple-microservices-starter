locals {
  eks_name = "${local.name}-eks"
}

# ---------------- IAM: control plane ----------------
data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.eks_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------------- IAM: worker nodes ----------------
data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  name               = "${local.eks_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # pull images from ECR
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # shell access via SSM, no SSH/bastion needed
  ])

  role       = aws_iam_role.eks_node.name
  policy_arn = each.value
}

# ---------------- Cluster ----------------
resource "aws_eks_cluster" "main" {
  name     = local.eks_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_kubernetes_version

  vpc_config {
    # Control-plane ENIs go in the private subnets created in vpc.tf
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true # so you can run kubectl from your laptop
    public_access_cidrs     = var.eks_endpoint_public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true # the IAM user/role running terraform becomes cluster admin
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# ---------------- Managed node group (PRIVATE subnets only) ----------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.eks_name}-default"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id # private only - nodes get no public IPs

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = var.eks_node_instance_types
  disk_size      = var.eks_node_disk_size

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size] # let the autoscaler / you change it without TF drift

    # Private nodes need a path to the internet (via NAT) to join the cluster and pull images.
    precondition {
      condition     = var.enable_nat_gateway
      error_message = "EKS nodes live in private subnets and need the NAT gateway. Set enable_nat_gateway = true."
    }
  }

  depends_on = [aws_iam_role_policy_attachment.eks_node]
}

# ---------------- Add-ons ----------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  # CoreDNS pods need nodes to schedule on
  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [aws_eks_node_group.main]
}

# ---------------- Let pods reach the databases ----------------
# Pods run on the nodes, which use the cluster's primary security group.
# The RDS security groups from security_groups.tf only trusted the per-service SGs,
# so add the cluster SG as an additional allowed source on port 5432.
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  for_each = var.backend_services

  security_group_id            = aws_security_group.rds[each.key].id
  description                  = "PostgreSQL from EKS nodes/pods (${each.key} DB)"
  referenced_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
