variable "launch_type" {
  description = "ECS launch type: EC2 or FARGATE. Controls task definition compatibility."
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["EC2", "FARGATE"], upper(var.launch_type))
    error_message = "launch_type must be either EC2 or FARGATE."
  }
}
variable "min_size" {
  description = "Minimum number of instances in the ECS Auto Scaling Group."
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances in the ECS Auto Scaling Group."
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired number of instances in the ECS Auto Scaling Group."
  type        = number
  default     = 0
}
variable "name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "tasks" {
  description = "Container definitions for the ECS task"
  # Map keyed by task name => { container_definition = <container json>, iam = { actions = <list>, resources = <list> } }
  # container_definition is the JSON structure for a single container in the task definition.
  # The cpu/memory values will be used for both the task and the container for simplicity.
  # iam contains actions and resources that will be used to dynamically create IAM policy statements.
  type = map(object({
    container_definition = object({
      name      = string
      image     = string
      cpu       = number
      memory    = number
      essential = bool
      environment = optional(list(object({
        name  = string
        value = string
      })))
      portMappings = optional(list(object({
        containerPort = number
        hostPort      = number
        protocol      = string
      })))
    })
    iam = optional(map(object({
      actions   = list(string)
      resources = list(string)
    })), {})
  }))
}

variable "vpc_id" {
  description = "VPC ID where the ECS service will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service network configuration."
  type        = list(string)
}

variable "cidr_blocks" {
  description = "List of CIDR blocks for security group ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_ids" {
  description = "List of security group IDs for the ECS service."
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP to Fargate tasks (only valid for public subnets)."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type for the ECS capacity provider's launch template"
  type        = string
}

variable "architecture" {
  description = "CPU architecture for ECS container instances (x86_64 or arm64). Must align with instance_type."
  type        = string
  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be one of: x86_64, arm64"
  }
}

variable "logging_enabled" {
  description = "Enable CloudWatch logging for tasks"
  type        = bool
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}