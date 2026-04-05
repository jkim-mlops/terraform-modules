# NAT Instance Design

## Problem

NAT Gateway data processing fees ($0.045/GB) are costing ~$92/month on ~2TB of data transfer. NAT Gateway also has a ~$32/month hourly charge. A NAT instance eliminates per-GB fees entirely, replacing them with a flat EC2 instance cost.

## Design

### Toggle

A `nat_type` variable (`"gateway"` | `"instance"`) controls which NAT path is active. All resources use `count` to ensure mutual exclusivity. Default is `"gateway"` for backwards compatibility.

A `nat_instance_type` variable (default `"t3.micro"`) controls the EC2 instance size when using `nat_type = "instance"`.

### NAT Gateway Path (existing)

Existing resources with `count = var.nat_type == "gateway" ? 1 : 0` added:

- `aws_eip.nat`
- `aws_nat_gateway.this`
- `aws_route.private_nat` (points to NAT gateway)

### NAT Instance Path (new)

Resources with `count = var.nat_type == "instance" ? 1 : 0`:

- **EIP:** `aws_eip.nat` (separate from gateway EIP, toggled by count)
- **Security Group:** `aws_security_group.nat` - ingress from VPC CIDR (all traffic), egress to `0.0.0.0/0`
- **AMI:** `data "aws_ami"` - latest Amazon Linux 2023
- **Launch Template:** `aws_launch_template.nat`
  - Instance type from variable
  - `source_dest_check = false` (network interfaces metadata)
  - IAM instance profile
  - Security group
  - User data (via `templatefile()`) that:
    - Enables IP forwarding (`sysctl net.ipv4.ip_forward=1`)
    - Configures iptables masquerade
    - Associates the EIP to itself via AWS CLI
    - Updates the private route table to point to its ENI via AWS CLI
- **ASG:** `aws_autoscaling_group.nat` - min=1, max=1, placed in first public subnet for auto-recovery
- **Route:** `aws_route.private_nat` (points to instance, created by user data on boot via `replace-route`)
- **IAM Role + Policy + Instance Profile:**
  - `ec2:AssociateAddress` (scoped to the EIP)
  - `ec2:ReplaceRoute` (scoped to the route table)
  - `ec2:DescribeRouteTables`

### User Data Script

```bash
#!/bin/bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
ENI_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/mac)/interface-id)

sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

aws ec2 associate-address --allocation-id ${eip_alloc_id} --instance-id $INSTANCE_ID --region ${region}
aws ec2 replace-route --route-table-id ${route_table_id} --destination-cidr-block 0.0.0.0/0 --network-interface-id $ENI_ID --region ${region}
```

Variables `${eip_alloc_id}`, `${route_table_id}`, and `${region}` are injected by Terraform's `templatefile()`.

### File Changes

| File | Change |
|------|--------|
| `modules/vpc/nat.tf` | New file - all NAT resources (gateway + instance) |
| `modules/vpc/main.tf` | Remove NAT Gateway section |
| `modules/vpc/variables.tf` | Add `nat_type`, `nat_instance_type` |
| `modules/vpc/outputs.tf` | No changes |
| `modules/vpc/example/main.tf` | Add `nat_type` usage |

### Auto-Recovery

The ASG (min=1, max=1) handles recovery. When an instance dies:

1. ASG launches a replacement in the same public subnet
2. User data runs on boot: grabs the EIP, updates the route table
3. Private subnet traffic resumes (~2-3 min downtime)
