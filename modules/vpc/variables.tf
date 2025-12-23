variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "region" {
  description = "AWS region for the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  description = "Subnet configurations for the VPC"
  type = map(object({
    availability_zone = string
    cidr_block        = string
    public            = bool
  }))
}