output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.network.private_subnet_id
}

output "public_instance_public_ip" {
  description = "Public IP of public EC2 instance"
  value       = module.ec2.public_instance_public_ip
}

output "private_instance_private_ip" {
  description = "Private IP of private EC2 instance"
  value       = module.ec2.private_instance_private_ip
}
