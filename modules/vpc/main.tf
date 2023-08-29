# REFERENCE:
# - Terraform EKS Cluster Creation by Anton Putra
#   Link: https://youtube.com/playlist?list=PLiMWaCMwGJXkeBzos8QuUxiYT6j8JYGE5


resource "aws_vpc" "main_vpc" {
  cidr_block                       = var.vpc_cidr_block
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr_blocks)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnets_cidr_blocks[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                        = "${var.vpc_name}-public-${var.azs[count.index]}"
    "kubernetes.io/cluster/eks" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets_cidr_blocks)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnets_cidr_blocks[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name                              = "${var.vpc_name}-private-${var.azs[count.index]}"
    "kubernetes.io/cluster/eks"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_eip" "nat" {
  count      = length(var.public_subnets_cidr_blocks)
  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_nat_gateway" "gw" {
  count         = length(var.public_subnets_cidr_blocks)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.vpc_name}-natgw"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.public_subnets_cidr_blocks)
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw[count.index].id
  }

  tags = {
    Name = "${var.vpc_name}-private[count.index]"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
