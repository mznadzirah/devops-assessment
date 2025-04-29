# Web Application Deployment on AWS (Terraform)

## Overview
This project provisions a scalable and secure infrastructure to host a web application (Online Photo Editing) in AWS platform by utilising IaC tool, Terraform.

# Challenge 1:   Infrastructure as Code (IaC)
## AWS Resources
### EC2 Instance Types

| Component            | Instance Type | Specs             | Justification                                    |
|----------------------|---------------|-------------------|--------------------------------------------|
| Frontend (Web/UI)    | t3.large      | 2 vCPUs, 8 GiB RAM | Assuming it is for hosting the web application and handling user logins and doesn't perform heavy processing task, a general-purpose instance would be sufficient to handle the services|
| Backend (Processing) | c7i.2xlarge   | 8 vCPUs, 16 GiB RAM| Assuming the backend processing involvig many image processing, editing and AI-related tasks. Hence, it recommended to use compute instance type|

- **Note: Instance specs are subject to change based on performance testing and optimization.**

## AWS Architecture Components
- Virtual Private Cloud (VPC)
- Subnets (Public and Private)
- Internet Gateway
- Route Tables
- Application Load Balancer (ALB)
- EC2 Instances (Frontend and Backend)

## Scalability
- Supports horizontal scalability.(Adding more instances when required)
- A *instance_count* Terraform variable allows adjusting the number of EC2 instances.
- Easily scale up/down by modifying the instance_count value.

## Security Best Practices
### Network Security
Custom VPC and Subnets: Isolated public and private subnets for resource separation.
- Internet Gateway and Routing: Set up an internet gateway and routing table so the Application Load Balancer (ALB) can be accessed from the internet
- Application Load Balancer (ALB) : Create public ALB receives traffic from the internet and forwards it to EC2 instances in a private network
- Web servers are placed in private subnets, preventing direct exposure to the internet.

## Security Groups
- SSH (Port 22) access restricted to public. Only allowed to office IP range or VPN users.
- HTTP (Port 80) access allowed to user in office IP range or VPN user.

# Challenge 2: Monitoring Integration
## Monitored Metrics for EC2 Instances
1. CPU Utilization
Metric Name: CPUUtilization
- This metric shows how much of the EC2 instance's CPU capacity is being used
- High CPU utilization can cause the application performance slow.
- Low CPU utilization indicates an under-utilized instance due to over provisioned spec

2. Disk Usage
Metric Names: DiskSpaceUtilization
- This metrics show the space utilization of the instance's storage.
- DiskSpaceUtilization: Percentage of disk space used on the instance's file system.
- High disk space usage can lead to storage issues may cause the system to become unresponsive.

3. Network Traffic
- Metric Names: NetworkIn, NetworkOut
- This metrics measure the volume of incoming and outgoing network traffic to and from the instance, respectively.
- NetworkIn: The number of bytes received by the instance.
- NetworkOut: The number of bytes sent by the instance.
- High network traffic will show spikes on the graph. Possible causes might be due to a misconfigured application making too many requests or DDoS attack
- Low Network Traffic indicates application isn't being utilized. There might be connectivity issues
  (e.g., DNS issues, firewall issues).

# Challenge 3 : Security Basics
### IAM Role and Policy

**Role:** EC2WebAppS3ReadRole  
**Policy:** S3ReadOnlyWebAppPolicy

- The role includes a custom policy that grants read-only (`s3:GetObject`) access to a specific S3 bucket that contains static content required by the web application.
- The EC2 instance can only **read** objects from the S3 bucket.
- Permissions are limited to the exact bucket path (`arn:aws:s3:::<bucket-name>/*`).