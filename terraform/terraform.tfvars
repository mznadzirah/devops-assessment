# terraform.tfvars

# AWS Region
aws_region = "ap-southeast-1"

# AMI IDs for the Web Server and Backend Server
ami_id = "ami-05ab12222a9f39021"

# Instance Types for Web Server and Backend Server
web_instance_type      = "t3.micro" # Instance type for web server
backend_instance_type  = "c7i.2xlarge" # Instance type for Backend server

# Instance Count for Web Server and Backend Server
web_instance_count = 2 # Instance count for web server
backend_instance_count  = 1 # Instance count for backend server

# VPC CIDR Block
vpc_cidr_block = "10.0.0.0/22"

# Subnet CIDR blocks for Web and Backend
# public_subnet_cidr_block = "10.0.0.0/24"
public_subnet_1_cidr_block = "10.0.0.0/24"
public_subnet_2_cidr_block = "10.0.1.0/24"
web_subnet_cidr_block    = "10.0.2.0/24"
backend_subnet_cidr_block     = "10.0.3.0/24"

# Office VPN CIDR block
office_vpn_cidr_block = "192.168.1.0/24"