<!-- BEGIN_TF_DOCS -->
# eks

Amazon EKS cluster with CPU and GPU node groups, IAM roles, and access management.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.27.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.27.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry.admin_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.admin_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_eks_node_group.gpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cpu_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.gpu_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cpu_nodes-AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cpu_nodes-AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cpu_nodes-AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cpu_nodes-AmazonS3ReadOnlyAccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.gpu_nodes-AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.gpu_nodes-AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.gpu_nodes-AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.gpu_nodes-AmazonS3ReadOnlyAccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_users"></a> [admin\_users](#input\_admin\_users) | List of IAM user/role ARNs that should have admin access to the EKS cluster. | `list(string)` | `[]` | no |
| <a name="input_cpu_node_group"></a> [cpu\_node\_group](#input\_cpu\_node\_group) | Configuration for the CPU node group | <pre>object({<br/>    instance_types = list(string)<br/>    disk_size      = number<br/>    desired_size   = number<br/>    max_size       = number<br/>    min_size       = number<br/>    ami_type       = string<br/>    capacity_type  = string<br/>  })</pre> | <pre>{<br/>  "ami_type": "BOTTLEROCKET_x86_64",<br/>  "capacity_type": "ON_DEMAND",<br/>  "desired_size": 1,<br/>  "disk_size": 50,<br/>  "instance_types": [<br/>    "t3.medium"<br/>  ],<br/>  "max_size": 3,<br/>  "min_size": 1<br/>}</pre> | no |
| <a name="input_data_volume_size"></a> [data\_volume\_size](#input\_data\_volume\_size) | Size in GB for the persistent volume to store downloaded data. | `number` | `20` | no |
| <a name="input_gpu_node_group"></a> [gpu\_node\_group](#input\_gpu\_node\_group) | Configuration for the GPU node group | <pre>object({<br/>    instance_types = list(string)<br/>    disk_size      = number<br/>    desired_size   = number<br/>    max_size       = number<br/>    min_size       = number<br/>    ami_type       = string<br/>    capacity_type  = string<br/>  })</pre> | <pre>{<br/>  "ami_type": "BOTTLEROCKET_x86_64_NVIDIA",<br/>  "capacity_type": "ON_DEMAND",<br/>  "desired_size": 0,<br/>  "disk_size": 100,<br/>  "instance_types": [<br/>    "g4dn.xlarge"<br/>  ],<br/>  "max_size": 2,<br/>  "min_size": 0<br/>}</pre> | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The desired Kubernetes version for the EKS cluster. | `string` | `"1.27"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_release_version"></a> [release\_version](#input\_release\_version) | The release version of the EKS optimized AMI. | `string` | `""` | no |
| <a name="input_s3_data_bucket"></a> [s3\_data\_bucket](#input\_s3\_data\_bucket) | The S3 bucket name containing data to be pulled by init containers. | `string` | `""` | no |
| <a name="input_s3_data_prefix"></a> [s3\_data\_prefix](#input\_s3\_data\_prefix) | The S3 prefix/key path for data objects to download. | `string` | `""` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnet IDs to use for the EKS cluster. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | The EKS cluster resource with all attributes |
| <a name="output_cluster_iam_role"></a> [cluster\_iam\_role](#output\_cluster\_iam\_role) | The IAM role for EKS cluster with all attributes |
| <a name="output_cpu_node_group"></a> [cpu\_node\_group](#output\_cpu\_node\_group) | The CPU EKS Node Group resource with all attributes |
| <a name="output_cpu_node_iam_role"></a> [cpu\_node\_iam\_role](#output\_cpu\_node\_iam\_role) | The IAM role for CPU EKS nodes with all attributes |
| <a name="output_gpu_node_group"></a> [gpu\_node\_group](#output\_gpu\_node\_group) | The GPU EKS Node Group resource with all attributes |
| <a name="output_gpu_node_iam_role"></a> [gpu\_node\_iam\_role](#output\_gpu\_node\_iam\_role) | The IAM role for GPU EKS nodes with all attributes |
<!-- END_TF_DOCS -->