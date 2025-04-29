terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

// Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

// VPC Configuration for CIDR block
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
}

// Web Subnet CIDR Block
resource "aws_subnet" "webserver-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.web_subnet_cidr_block
}

// Backend Subnet CIDR Block
resource "aws_subnet" "backend-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.backend_subnet_cidr_block
}

// Web Instance
resource "aws_instance" "webapp" {
  ami                    = var.ami_id
  instance_type          = var.web_instance_type
  count                  = var.web_instance_count
  subnet_id              = aws_subnet.webserver-subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_instance_profile.name
}

output "webapp_instance_ids" {
  value = aws_instance.webapp[*].id
}

// Backend Instance
resource "aws_instance" "backend" {
  ami           = var.ami_id
  instance_type = var.backend_instance_type
  count         = var.backend_instance_count
  subnet_id     = aws_subnet.backend-subnet.id
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_instance_profile.name
}

output "backend_instance_ids" {
  value = aws_instance.backend[*].id
}

// SecurityGroup
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP, HTTPS, and restricted SSH traffic"
  vpc_id      = aws_vpc.vpc.id

  // Allow HTTP (port 80) traffic from specific IP
  ingress {
    description = "Allow HTTP from specific IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.office_vpn_cidr_block]
  }

  // Allow HTTPS (port 443) traffic from anywhere
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow SSH (port 22) from a specific IP or your office VPN
  ingress {
    description = "Allow SSH traffic on port 22 from a specific IP (e.g: VPN IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.office_vpn_cidr_block]
  }
}

// Application Load Balancer
resource "aws_lb" "app-lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
    ]

  enable_deletion_protection = true
}

// Application Load Balancer Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Allow public HTTP access
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Allow public HTTPS access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create an Internet Gateway (IGW) and attach it to the VPC
resource "aws_internet_gateway" "web-igw" {
  vpc_id = aws_vpc.vpc.id
}

// Create a Public Subnet 1 in the VPC
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_1_cidr_block
  availability_zone       = "ap-southeast-1c"  // Singapore AZ1
  map_public_ip_on_launch = true // IMPORTANT for Public Subnet
}

// Create a Public Subnet 2 in the VPC
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_2_cidr_block
  availability_zone       = "ap-southeast-1b"  // Singapore AZ1
  map_public_ip_on_launch = true // IMPORTANT for Public Subnet
}

// Create a Route Table that defines routes for public access
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0" // send all traffic
    gateway_id = aws_internet_gateway.web-igw.id
  }
}

// Associate the Public Subnet with the Route Table (to enable routing via the IGW)
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

// Associate the Public Subnet with the Route Table (to enable routing via the IGW)
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

// Monitoring
// EC2 Metrics Dashboard
resource "aws_cloudwatch_dashboard" "ec2_cpu_dashboard" {
  dashboard_name = "EC2-CPU-Dashboard"

  dashboard_body = jsonencode({
    widgets = flatten([
      // WebApp instances
      [
        for idx, instance in aws_instance.webapp : {
          type   = "metric"
          x      = 0
          y      = idx * 6
          width  = 12
          height = 6
          properties = {
            metrics = [
              [ "AWS/EC2", "CPUUtilization", "InstanceId", instance.id ]
            ]
            view    = "timeSeries"
            stacked = false
            region  = var.aws_region
            title   = "WebApp CPU - ${instance.id}"
          }
        }
      ],

      // Backend instances
      [
        for idx, instance in aws_instance.backend : {
          type   = "metric"
          x      = 0
          y      = (length(aws_instance.webapp) + idx) * 6
          width  = 12
          height = 6
          properties = {
            metrics = [
              [ "AWS/EC2", "CPUUtilization", "InstanceId", instance.id ]
            ]
            view    = "timeSeries"
            stacked = false
            region  = var.aws_region
            title   = "backend CPU - ${instance.id}"
          }
        }
      ]
    ])
  })
}

resource "aws_cloudwatch_dashboard" "disk_dashboard" {
  dashboard_name = "EC2-Disk-Dashboard"
  dashboard_body = jsonencode({
    widgets = flatten([
      [
        for idx, instance in aws_instance.webapp : {
          type = "metric"
          x = 0
          y = idx * 6
          width = 12
          height = 6
          properties = {
            metrics = [
              [ "CWAgent", "disk_used_percent", "InstanceId", instance.id, "path", "/", "fstype", "xfs" ]
            ]
            view = "timeSeries"
            stacked = false
            region = var.aws_region
            title = "WebApp Disk Usage - ${instance.id}"
          }
        }
      ],
      [
        for idx, instance in aws_instance.backend : {
          type = "metric"
          x = 0
          y = (length(aws_instance.webapp) + idx) * 6
          width = 12
          height = 6
          properties = {
            metrics = [
              [ "CWAgent", "disk_used_percent", "InstanceId", instance.id, "path", "/", "fstype", "xfs" ]
            ]
            view = "timeSeries"
            stacked = false
            region = var.aws_region
            title = "backend Disk Usage - ${instance.id}"
          }
        }
      ]
    ])
  })
}


resource "aws_cloudwatch_dashboard" "network_dashboard" {
  dashboard_name = "EC2-Network-Dashboard"
  dashboard_body = jsonencode({
    widgets = flatten([
      [
        for idx, instance in aws_instance.webapp : {
          type = "metric"
          x = 0
          y = idx * 6
          width = 12
          height = 6
          properties = {
            metrics = [
              [ "AWS/EC2", "NetworkIn", "InstanceId", instance.id ],
              [ ".", "NetworkOut", ".", "." ]
            ]
            view = "timeSeries"
            stacked = false
            region = var.aws_region
            title = "WebApp Network I/O - ${instance.id}"
          }
        }
      ],
      [
        for idx, instance in aws_instance.backend : {
          type = "metric"
          x = 0
          y = (length(aws_instance.webapp) + idx) * 6
          width = 12
          height = 6
          properties = {
            metrics = [
              [ "AWS/EC2", "NetworkIn", "InstanceId", instance.id ],
              [ ".", "NetworkOut", ".", "." ]
            ]
            view = "timeSeries"
            stacked = false
            region = var.aws_region
            title = "backend Network I/O - ${instance.id}"
          }
        }
      ]
    ])
  })
}

// IAM Policy allowing read access to a specific S3 bucket
resource "aws_iam_policy" "ec2_s3_read_policy" {
  name        = "EC2S3ReadAccessPolicy"
  description = "Policy allowing EC2 to read from specific S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::web-bucket",
          "arn:aws:s3:::web-bucket/*"
        ]
      }
    ]
  })
}

// IAM Role to be assumed by EC2
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "EC2S3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

// Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.ec2_s3_read_policy.arn
}

// Instance profile to link the IAM role with EC2
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "EC2S3InstanceProfile"
  role = aws_iam_role.ec2_s3_access_role.name
}
