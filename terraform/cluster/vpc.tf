# Create VPC
resource "aws_vpc" "k8s_vpc-main" {
  cidr_block = "10.0.0.0/16"

  tags = var.vpcTags
}

# Select a random availability zone in the provided region
resource "random_shuffle" "k8s_vpc-region" {
  input        = ["${var.region}a", "${var.region}b", "${var.region}c"]
  result_count = 1
}

# Create a public subnet in the selected availability zone
resource "aws_subnet" "k8s_vpc-publicsubnet" {
  vpc_id            = aws_vpc.k8s_vpc-main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = random_shuffle.k8s_vpc-region.result[0]

  tags = var.subnetTags
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "k8s_vpc-igw" {
  vpc_id = aws_vpc.k8s_vpc-main.id

  tags = var.igwTags
}


# Create a route table for the public subnet
resource "aws_route_table" "k8s_vpc-publicrt" {
  vpc_id = aws_vpc.k8s_vpc-main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_vpc-igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.k8s_vpc-igw.id
  }

  tags = var.publicRtTags
}


# Create a route table association between the public subnet and the public route table
resource "aws_route_table_association" "k8s_vpc-public1rta" {
  subnet_id      = aws_subnet.k8s_vpc-publicsubnet.id
  route_table_id = aws_route_table.k8s_vpc-publicrt.id
}

# Create a sg for the VPC
resource "aws_security_group" "k8s_vpc-sg" {
  name   = var.sgName
  vpc_id = aws_vpc.k8s_vpc-main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Etcd
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nodeports
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic is allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}