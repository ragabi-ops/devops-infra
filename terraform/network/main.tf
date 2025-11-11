# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Public subnets (2)
resource "aws_subnet" "public" {
  for_each = {
    a = { az = var.azs[0], cidr = var.public_subnet_cidrs[0] }
    b = { az = var.azs[1], cidr = var.public_subnet_cidrs[1] }
  }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}-public-${each.key}"
    Project = var.project_name
    Tier    = "public"
  }
}

# Private subnets (2)
resource "aws_subnet" "private" {
  for_each = {
    a = { az = var.azs[0], cidr = var.private_subnet_cidrs[0] }
    b = { az = var.azs[1], cidr = var.private_subnet_cidrs[1] }
  }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name    = "${var.project_name}-private-${each.key}"
    Project = var.project_name
    Tier    = "private"
  }
}

# EIPs for NAT
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : 2
  domain = "vpc"
  tags = {
    Name    = "${var.project_name}-nat-eip-${count.index}"
    Project = var.project_name
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, var.single_nat_gateway ? 0 : count.index)
  tags = {
    Name    = "${var.project_name}-nat-${count.index}"
    Project = var.project_name
  }
  depends_on = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route tables
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id

  dynamic "route" {
    for_each = [for i in range(var.single_nat_gateway ? 1 : 1) : i] # placeholder to allow 0 routes in plan
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[index(keys(aws_subnet.private), each.key)].id
    }
  }

  tags = {
    Name    = "${var.project_name}-private-rt-${each.key}"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Basic default security group to allow internal traffic
resource "aws_security_group" "default_app" {
  name        = "${var.project_name}-default-app-sg"
  description = "Allow internal VPC traffic; egress to Internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "VPC internal"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-default-app-sg"
    Project = var.project_name
  }
}
