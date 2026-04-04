/**
 * NAT resources - configurable between NAT Gateway and NAT Instance.
 * Controlled by var.nat_type ("gateway" or "instance").
 */


# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------

resource "aws_eip" "nat_gateway" {
  count  = var.nat_type == "gateway" ? 1 : 0
  domain = "vpc"
  tags = {
    Name = var.name
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_type == "gateway" ? 1 : 0
  allocation_id = aws_eip.nat_gateway[0].id
  subnet_id     = [for s in aws_subnet.this : s.id if s.map_public_ip_on_launch][0]

  tags = {
    Name = var.name
  }
}

resource "aws_route" "private_nat_gateway" {
  count                  = var.nat_type == "gateway" ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}


# -----------------------------------------------------------------------------
# NAT Instance
# -----------------------------------------------------------------------------

locals {
  nat_instance = var.nat_type == "instance" ? 1 : 0
}

data "aws_ami" "al2023" {
  count       = local.nat_instance
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "nat_instance" {
  count  = local.nat_instance
  domain = "vpc"
  tags = {
    Name = "${var.name}-nat-instance"
  }
}

resource "aws_security_group" "nat" {
  count       = local.nat_instance
  name        = "${var.name}-nat-instance"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-nat-instance"
  }
}

resource "aws_iam_role" "nat" {
  count = local.nat_instance
  name  = "${var.name}-nat-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.name}-nat-instance"
  }
}

resource "aws_iam_role_policy" "nat" {
  count = local.nat_instance
  name  = "${var.name}-nat-instance"
  role  = aws_iam_role.nat[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = [
          aws_eip.nat_instance[0].arn,
          "arn:aws:ec2:${var.region}:*:instance/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:ReplaceRoute", "ec2:CreateRoute"]
        Resource = aws_route_table.private.arn
      },
      {
        Effect   = "Allow"
        Action   = "ec2:DescribeRouteTables"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nat" {
  count = local.nat_instance
  name  = "${var.name}-nat-instance"
  role  = aws_iam_role.nat[0].name
}

resource "aws_launch_template" "nat" {
  count         = local.nat_instance
  name          = "${var.name}-nat-instance"
  image_id      = data.aws_ami.al2023[0].id
  instance_type = var.nat_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.nat[0].name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nat[0].id]
    device_index                = 0
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(templatefile(
    "${path.module}/templates/nat-instance-userdata.sh.tftpl",
    {
      eip_alloc_id   = aws_eip.nat_instance[0].id
      route_table_id = aws_route_table.private.id
      region         = var.region
    }
  ))

  tags = {
    Name = "${var.name}-nat-instance"
  }
}

resource "aws_autoscaling_group" "nat" {
  count               = local.nat_instance
  name                = "${var.name}-nat-instance"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [[for s in aws_subnet.this : s.id if s.map_public_ip_on_launch][0]]

  launch_template {
    id      = aws_launch_template.nat[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-nat-instance"
    propagate_at_launch = true
  }
}

# -----------------------------------------------------------------------------
# VPC Interface Endpoints (NAT Instance only)
# -----------------------------------------------------------------------------

resource "aws_security_group" "ecr_endpoint" {
  count       = local.nat_instance
  name        = "${var.name}-vpc-endpoints"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  tags = {
    Name = "${var.name}-vpc-endpoints"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count             = local.nat_instance
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.this : s.id if !s.map_public_ip_on_launch]
  security_group_ids = [aws_security_group.ecr_endpoint[0].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.name}-ecr-api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count             = local.nat_instance
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.this : s.id if !s.map_public_ip_on_launch]
  security_group_ids = [aws_security_group.ecr_endpoint[0].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.name}-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "logs" {
  count             = local.nat_instance
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.this : s.id if !s.map_public_ip_on_launch]
  security_group_ids = [aws_security_group.ecr_endpoint[0].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.name}-logs"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  count             = local.nat_instance
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.this : s.id if !s.map_public_ip_on_launch]
  security_group_ids = [aws_security_group.ecr_endpoint[0].id]

  private_dns_enabled = true

  tags = {
    Name = "${var.name}-ssm"
  }
}
