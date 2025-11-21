provider "aws" {
  region = "us-east-1"  # Set your preferred AWS region
}

# Create an EC2 instance
resource "aws_instance" "my_ec2" {
  ami           = var.ami_id         # AMI ID as a variable
  instance_type = var.instance_type  # Instance type as a variable
  #count = var.instance_count
  key_name = "Ridwan"


  tags = {
    Name = "DevSecOps"
  }
}

# Create an Elastic IP
resource "aws_eip" "my_eip" {
  instance = aws_instance.my_ec2.id  # Attach EIP to the EC2 instance
}


# VPC (simple default VPC for testing)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "monitoring-cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [
  "subnet-0b129e33cfee52706", # us-east-1a
  "subnet-078161dc0eab21b77", # us-east-1b
  "subnet-007462534c7fef10b", # us-east-1c
  "subnet-09f1d3ac3b09889d7", # us-east-1d
  "subnet-056db44779f734b63"  # us-east-1f
    ]

  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

# Node group IAM role
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

# Node group
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policies
  ]
}
