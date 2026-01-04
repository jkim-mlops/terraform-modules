output "cluster" {
  description = "The EKS cluster resource with all attributes"
  value       = aws_eks_cluster.this
}

output "cpu_node_group" {
  description = "The CPU EKS Node Group resource with all attributes"
  value       = aws_eks_node_group.cpu
}

output "gpu_node_group" {
  description = "The GPU EKS Node Group resource with all attributes"
  value       = aws_eks_node_group.gpu
}

output "cpu_node_iam_role" {
  description = "The IAM role for CPU EKS nodes with all attributes"
  value       = aws_iam_role.cpu_nodes
}

output "gpu_node_iam_role" {
  description = "The IAM role for GPU EKS nodes with all attributes"
  value       = aws_iam_role.gpu_nodes
}

output "cluster_iam_role" {
  description = "The IAM role for EKS cluster with all attributes"
  value       = aws_iam_role.cluster
}
