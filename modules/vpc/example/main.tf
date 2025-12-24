

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