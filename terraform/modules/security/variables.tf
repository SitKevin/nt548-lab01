variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Public IP CIDR allowed to SSH into public EC2"
  type        = string
}
