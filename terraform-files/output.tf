output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.my_ec2.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.my_eip.public_ip
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}


