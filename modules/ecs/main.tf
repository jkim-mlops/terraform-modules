//
// CloudWatch Log Groups

locals {
  # Filter tasks that have IAM requirements
  tasks_with_iam = {
    for task_name, task_config in var.tasks : task_name => task_config
    if length(task_config.iam) > 0
  }
}

resource "aws_cloudwatch_log_group" "task_logs" {
  for_each = var.logging_enabled ? var.tasks : {}

  name              = "/ecs/${var.name}/${each.key}"
  retention_in_days = var.log_retention_days
}

//
// Cluster

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

//
// IAM Permissions

resource "aws_iam_role" "this" {
  name               = "${var.name}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "task_exec" {
  statement {
    sid = "ECRPull"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-task-exec-inline"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.task_exec.json
}

//
// Task IAM Roles (for tasks that need AWS API access)

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create task roles for each task that has IAM requirements
resource "aws_iam_role" "task" {
  for_each = local.tasks_with_iam

  name               = "${var.name}-${each.key}-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

# Create dynamic IAM policy documents for each task
data "aws_iam_policy_document" "task" {
  for_each = local.tasks_with_iam

  dynamic "statement" {
    for_each = each.value.iam
    content {
      sid       = statement.key
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# Attach policies to task roles
resource "aws_iam_role_policy" "task" {
  for_each = local.tasks_with_iam

  name   = "${var.name}-${each.key}-task-policy"
  role   = aws_iam_role.task[each.key].id
  policy = data.aws_iam_policy_document.task[each.key].json
}

//
// EC2 Instance Role & Instance Profile (for ECS container instances)
// Provides permissions for the EC2 host to register with ECS and send logs/metrics.

data "aws_iam_policy_document" "instance_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name}-ecs-instance"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json
}

resource "aws_iam_role_policy_attachment" "instance_ecs" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-ecs-instance"
  role = aws_iam_role.instance.name
}

//
// Task Definition

resource "aws_ecs_task_definition" "this" {
  for_each                 = var.tasks
  family                   = each.key
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = each.value.container_definition.cpu
  memory                   = each.value.container_definition.memory
  task_role_arn            = length(each.value.iam) > 0 ? aws_iam_role.task[each.key].arn : null
  execution_role_arn       = aws_iam_role.this.arn
  container_definitions = jsonencode([
    merge(
      each.value.container_definition,
      var.logging_enabled ? {
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.task_logs[each.key].name
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      } : {}
    )
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = upper(var.architecture == "arm64" ? "ARM64" : "X86_64")
  }

}

//
// Launch Template (ECS Optimized)

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  # ECS optimized Amazon Linux 2 (or 2023) images. Pattern differs by architecture.
  # Examples:
  #  - amzn2-ami-ecs-hvm-*-x86_64-ebs
  #  - amzn2-ami-ecs-hvm-*-arm64-ebs
  filter {
    name = "name"
    values = [
      var.architecture == "arm64" ? "amzn2-ami-ecs-hvm-*-arm64-ebs" : "amzn2-ami-ecs-hvm-*-x86_64-ebs"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-ecs-"
  image_id      = data.aws_ami.this.id # ECS optimized AMI selected above
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }

  vpc_security_group_ids = length(var.security_group_ids) == 0 ? [aws_security_group.this.id] : var.security_group_ids

  // ensure instances join the correct ECS cluster
  user_data = base64encode(<<-EOT
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.this.name}" >> /etc/ecs/ecs.config
  EOT
  )
}

//
// Capacity Provider (Scale to Zero)

resource "aws_autoscaling_group" "this" {
  name                  = "${var.name}-scale-to-zero"
  min_size              = 0
  max_size              = 1
  desired_capacity      = 0
  vpc_zone_identifier   = var.subnet_ids
  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  # Force instance replacement when launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      # allow going to 0 instances during refresh
      min_healthy_percentage = 0
    }
    triggers = ["tag", "desired_capacity"]
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = aws_autoscaling_group.this.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
      instance_warmup_period = 120
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 0
  }
}

//
// Service

resource "aws_security_group" "this" {
  name   = "default-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "this" {
  for_each = var.tasks

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = 0

  force_new_deployment = true

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 0
    weight            = 1
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = length(var.security_group_ids) == 0 ? [aws_security_group.this.id] : var.security_group_ids
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}


