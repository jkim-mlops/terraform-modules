module "vpc" {
  // please remember to version constrain this module with `?ref=<your version>`
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/vpc"

  name       = var.name
  region     = var.aws_region
  cidr_block = "10.0.0.0/16"
  subnets = {
    a-public = {
      availability_zone = "${var.aws_region}a"
      cidr_block        = "10.0.1.0/24"
      public            = true
    }
    b-public = {
      availability_zone = "${var.aws_region}b"
      cidr_block        = "10.0.2.0/24"
      public            = true
    }
    a-private = {
      availability_zone = "${var.aws_region}a"
      cidr_block        = "10.0.3.0/24"
      public            = false
    }
    b-private = {
      availability_zone = "${var.aws_region}b"
      cidr_block        = "10.0.4.0/24"
      public            = false
    }
  }
}

module "eks" {
  // please remember to version constrain this module with `?ref=<your version>`
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/eks"

  name               = var.name
  kubernetes_version = "1.28"
  subnet_ids         = module.vpc.private_subnet_ids

  cpu_node_group = {
    instance_types = ["t3.medium"]
    disk_size      = 50
    desired_size   = 2
    max_size       = 4
    min_size       = 1
    ami_type       = "BOTTLEROCKET_x86_64"
    capacity_type  = "ON_DEMAND"
  }

  gpu_node_group = {
    instance_types = ["g4dn.xlarge"]
    disk_size      = 100
    desired_size   = 0
    max_size       = 2
    min_size       = 0
    ami_type       = "BOTTLEROCKET_x86_64_NVIDIA"
    capacity_type  = "SPOT"
  }
}
