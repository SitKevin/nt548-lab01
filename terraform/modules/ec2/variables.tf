variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for public EC2"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for private EC2"
  type        = string
}

variable "public_security_group" {
  description = "Security group ID for public EC2"
  type        = string
}

variable "private_security_group" {
  description = "Security group ID for private EC2"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}
