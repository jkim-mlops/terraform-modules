//
// VPC and Subnets

resource "aws_vpc" "this" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "this" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "${var.name}-${each.key}"
  }
}

//
// Route Tables to Public and Private Subnets

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private"
  }
}

resource "aws_route_table_association" "this" {
  for_each       = var.subnets
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = each.value.public ? aws_route_table.public.id : aws_route_table.private.id
}

//
// Network Connections (VPC Endpoints and Internet Gateway)

resource "aws_vpc_endpoint" "this" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Environment = "${var.name}-s3"
  }
}

resource "aws_vpc_endpoint_route_table_association" "this" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.this.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-ig"
  }
}


//
// NAT Gateway

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = var.name
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = [for s in aws_subnet.this : s.id if s.map_public_ip_on_launch][0]

  tags = {
    Name = var.name
  }
}

# Add route to NAT Gateway for private subnets
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}