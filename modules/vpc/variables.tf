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

variable "nat_type" {
  description = "Type of NAT for private subnet internet access: 'gateway', 'instance', or 'none' (disables NAT and interface endpoints)"
  type        = string
  default     = "gateway"

  validation {
    condition     = contains(["gateway", "instance", "none"], var.nat_type)
    error_message = "nat_type must be 'gateway', 'instance', or 'none'"
  }
}

variable "nat_instance_type" {
  description = "EC2 instance type for NAT instance (only used when nat_type = 'instance')"
  type        = string
  default     = "t3.micro"
}