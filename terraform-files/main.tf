provider "aws" {
  region = "us-east-1"
}

#############################
# EC2 INSTANCE (optional)
#############################

resource "aws_instance" "my_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = "main.02"

  tags = {
    Name = "DevSecOps"
  }
}

resource "aws_eip" "my_eip" {
  instance = aws_instance.my_ec2.id
}

#############################
# VPC + SUBNET DISCOVERY
# Using DEFAULT VPC for testing (not recommended for prod)
#############################

data "aws_vpc" "default" {
  default = true
}

# Only select subnets in supported AZs for EKS control plane
data "aws_subnets" "eks_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c"] # EKS-supported AZs
  }
}

#############################
# IAM ROLES
#############################

# EKS Cluster Role
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#############################
# EKS CLUSTER
#############################

resource "aws_eks_cluster" "eks" {
  name     = "monitoring-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = data.aws_subnets.eks_private.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

#############################
# NODE GROUP IAM ROLE
#############################

resource "aws_iam_role" "node_role" {
  name = "eks-node-role"

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
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.node_role.name
  policy_arn = each.value
}

#############################
# NODE GROUP
#############################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node_role.arn

  subnet_ids     = data.aws_subnets.eks_private.ids
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policies
  ]
}
