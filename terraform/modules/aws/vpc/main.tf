################################################################################
# AWS VPC Module
# Creates: VPC, private/public subnets per AZ, Internet Gateway, NAT Gateway,
# route tables, and Security Groups for EKS nodes and EFS
################################################################################

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = var.vpc_name
    # Required by EKS so it can discover this VPC
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# ── Subnets ───────────────────────────────────────────────────────────────────

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.prefix}-snet-private-${var.availability_zones[count.index]}"
    # EKS discovers private subnets for internal load balancers
    "kubernetes.io/role/internal-elb"                     = "1"
    "kubernetes.io/cluster/${var.cluster_name}"            = "shared"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.prefix}-snet-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "shared"
  })
}

# ── Internet Gateway + NAT Gateway ───────────────────────────────────────────

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.prefix}-igw" })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.prefix}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.tags, { Name = "${var.prefix}-nat" })
  depends_on    = [aws_internet_gateway.igw]
}

# ── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, { Name = "${var.prefix}-rt-private" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, { Name = "${var.prefix}-rt-public" })
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Security Group — EKS nodes ────────────────────────────────────────────────

resource "aws_security_group" "eks_nodes" {
  name        = "${var.prefix}-sg-eks-nodes"
  description = "EKS node security group - allows internal cluster traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow all intra-cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow NFS from EFS mount targets"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.prefix}-sg-eks-nodes" })
}

# ── Security Group — EFS mount targets ───────────────────────────────────────

resource "aws_security_group" "efs" {
  name        = "${var.prefix}-sg-efs"
  description = "EFS mount target - allow NFS from EKS nodes"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "NFS from EKS nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.prefix}-sg-efs" })
}
