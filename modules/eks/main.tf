/**
 * # eks
 *
 * Amazon EKS cluster with CPU and GPU node groups, IAM roles, and access management.
 */

resource "aws_eks_cluster" "this" {
  name = var.name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster,
  ]
}

//
// EKS Cluster IAM Role

resource "aws_iam_role" "cluster" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

//
// CPU Node Group IAM Role

resource "aws_iam_role" "cpu_nodes" {
  name = "${var.name}-cpu-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cpu_nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cpu_nodes.name
}

resource "aws_iam_role_policy_attachment" "cpu_nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cpu_nodes.name
}

resource "aws_iam_role_policy_attachment" "cpu_nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cpu_nodes.name
}

resource "aws_iam_role_policy_attachment" "cpu_nodes-AmazonS3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.cpu_nodes.name
}

//
// GPU Node Group IAM Role

resource "aws_iam_role" "gpu_nodes" {
  name = "${var.name}-gpu-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "gpu_nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.gpu_nodes.name
}

resource "aws_iam_role_policy_attachment" "gpu_nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.gpu_nodes.name
}

resource "aws_iam_role_policy_attachment" "gpu_nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.gpu_nodes.name
}

resource "aws_iam_role_policy_attachment" "gpu_nodes-AmazonS3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.gpu_nodes.name
}

//
// CPU EKS Node Group
resource "aws_eks_node_group" "cpu" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-cpu-node-group"
  node_role_arn   = aws_iam_role.cpu_nodes.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.cpu_node_group.instance_types
  disk_size       = var.cpu_node_group.disk_size

  scaling_config {
    desired_size = var.cpu_node_group.desired_size
    max_size     = var.cpu_node_group.max_size
    min_size     = var.cpu_node_group.min_size
  }

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = var.source_security_group_ids
  }

  ami_type        = var.cpu_node_group.ami_type
  capacity_type   = var.cpu_node_group.capacity_type
  release_version = var.release_version

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cpu_nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cpu_nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cpu_nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.cpu_nodes-AmazonS3ReadOnlyAccess,
  ]
}

//
// GPU EKS Node Group
resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-gpu-node-group"
  node_role_arn   = aws_iam_role.gpu_nodes.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.gpu_node_group.instance_types
  disk_size       = var.gpu_node_group.disk_size

  scaling_config {
    desired_size = var.gpu_node_group.desired_size
    max_size     = var.gpu_node_group.max_size
    min_size     = var.gpu_node_group.min_size
  }

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = var.source_security_group_ids
  }

  ami_type        = var.gpu_node_group.ami_type
  capacity_type   = var.gpu_node_group.capacity_type
  release_version = var.release_version

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.gpu_nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.gpu_nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.gpu_nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.gpu_nodes-AmazonS3ReadOnlyAccess,
  ]
}

//
// EKS Access Entries
resource "aws_eks_access_entry" "admin_users" {
  for_each      = toset(var.admin_users)
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_users" {
  for_each      = toset(var.admin_users)
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_users]
}
