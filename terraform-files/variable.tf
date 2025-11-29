variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0866a3c8686eaeeba"  # AMI ID
}

variable "instance_type" {
  description = "Type of EC2 instance"
  default     = "t3.medium"
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  default     = 2
}


