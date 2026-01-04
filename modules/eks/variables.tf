variable "name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "The desired Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.27"
}

variable "subnet_ids" {
  description = "The subnet IDs to use for the EKS cluster."
  type        = list(string)
}

# CPU Node Group Configuration
variable "cpu_node_group" {
  description = "Configuration for the CPU node group"
  type = object({
    instance_types = list(string)
    disk_size      = number
    desired_size   = number
    max_size       = number
    min_size       = number
    ami_type       = string
    capacity_type  = string
  })
  default = {
    instance_types = ["t3.medium"]
    disk_size      = 50
    desired_size   = 1
    max_size       = 3
    min_size       = 1
    ami_type       = "BOTTLEROCKET_x86_64"
    capacity_type  = "ON_DEMAND"
  }
}

# GPU Node Group Configuration
variable "gpu_node_group" {
  description = "Configuration for the GPU node group"
  type = object({
    instance_types = list(string)
    disk_size      = number
    desired_size   = number
    max_size       = number
    min_size       = number
    ami_type       = string
    capacity_type  = string
  })
  default = {
    instance_types = ["g4dn.xlarge"]
    disk_size      = 100
    desired_size   = 0
    max_size       = 2
    min_size       = 0
    ami_type       = "BOTTLEROCKET_x86_64_NVIDIA"
    capacity_type  = "ON_DEMAND"
  }
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for the EKS node groups."
  type        = string
  default     = ""
}

variable "source_security_group_ids" {
  description = "The security group IDs that are allowed to SSH into the EKS nodes."
  type        = list(string)
  default     = []
}

variable "release_version" {
  description = "The release version of the EKS optimized AMI."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

variable "admin_users" {
  description = "List of IAM user/role ARNs that should have admin access to the EKS cluster."
  type        = list(string)
  default     = []
}

variable "s3_data_bucket" {
  description = "The S3 bucket name containing data to be pulled by init containers."
  type        = string
  default     = ""
}

variable "s3_data_prefix" {
  description = "The S3 prefix/key path for data objects to download."
  type        = string
  default     = ""
}

variable "data_volume_size" {
  description = "Size in GB for the persistent volume to store downloaded data."
  type        = number
  default     = 20
}