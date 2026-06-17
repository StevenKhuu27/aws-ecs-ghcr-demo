# Networking - use the DEFAULT VPC/subnets so you never create a (paid) NAT Gateway.
# Default subnets are public + auto-assign a public IP, which the EC2 host needs to
# pull from GHCR and reach the ECS control plane.

# Look up the default VPC.
data "aws_vpc" "default" {
  default = true
}

# Look up the subnets in that VPC (you'll feed these to the ASG).
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for the EC2 host: inbound on the container port, all egress.
resource "aws_security_group" "ecs_host" {
  name        = "${var.project}-ecs-host-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.ecs_host.id
  cidr_ipv4         = var.ingress_cidr
  from_port         = var.container_port
  ip_protocol       = "tcp"
  to_port           = var.container_port
}
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.ecs_host.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}