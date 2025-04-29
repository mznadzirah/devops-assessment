# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

# Instance Type for Web Server
variable "web_instance_type" {
  description = "EC2 instance type for web server"
  type        = string
}

# Instance Count for Web Server
variable "web_instance_count" {
  description = "Number of EC2 instances for web server"
  type        = number
}

# Instance Type for Backend Server
variable "backend_instance_type" {
  description = "EC2 instance type for Backend server"
  type        = string
}

# Instance Count for Backend Server
variable "backend_instance_count" {
  description = "Number of EC2 instances for Backend server"
  type        = number
}

# AMI ID
variable "ami_id" {
  description = "AMI ID to use"
  type        = string
}

## VPC ID
#variable "vpc_id" {
#  type = string
#}

# VPC CIDR Block
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/22" # Default value if not provided
}

# Public Subnet CIDR Block
variable "public_subnet_1_cidr_block" {
  description = "CIDR block for the web subnet"
  type        = string
  default     = "10.0.0.0/24" # Default value if not provided
}

# Public Subnet CIDR Block
variable "public_subnet_2_cidr_block" {
  description = "CIDR block for the web subnet"
  type        = string
  default     = "10.0.1.0/24" # Default value if not provided
}

# Web Subnet CIDR Block
variable "web_subnet_cidr_block" {
  description = "CIDR block for the web subnet"
  type        = string
  default     = "10.0.2.0/24" # Default value if not provided
}

# Backend Subnet CIDR Block
variable "backend_subnet_cidr_block" {
  description = "CIDR block for the Backend subnet"
  type        = string
  default     = "10.0.3.0/24" # Default value if not provided
}

# Backend Subnet CIDR Block
variable "office_vpn_cidr_block" {
  description = "CIDR block for office VPN"
  type        = string
  default     = "192.168.1.0/24" # Default value if not provided
}

