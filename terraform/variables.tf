variable "aws_region" {
  description = "AWS region used for deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "nt548-lab01"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "ap-southeast-1a"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP CIDR allowed to SSH to public EC2"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}
