/**
 * NAT resources - configurable between NAT Gateway and NAT Instance.
 * Controlled by var.nat_type ("gateway" or "instance").
 */


//
// NAT Gateway

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
