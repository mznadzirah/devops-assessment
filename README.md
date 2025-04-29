# Infrastructure Assessment – Photo Editing Web Application

This repository contains the infrastructure for deploying a photo editing web application on AWS using Terraform and designing CI/CD pipelines.

## Folder Structure

- `terraform/` – Contains all Infrastructure as Code (IaC) scripts using Terraform.
- `cicd-pipeline/` – Contains the CI/CD pipeline design plan

Each folder includes its own `README.md` with more details

---

## Approach
- **Terraform:** Define EC2 instance type, Cloudwatch setup, IAM role, VPC and subnet setup in Terraform script.

- **CI/CD:** A separate pipeline for application deployment/updates and rollback plan

---

## Setup Instructions
### Pre-requisite tool
- AWS cli
- terraform cli

1. **Configure AWS Credentials:**
   ```bash
   aws configure

2. Run terraform script
   ```bash
   cd terraform
   terraform init
   // Pass specific instance type to variable
   terraform plan -var="web_instance_type=t3.large" -var="backend_instance_type=t2.large"
   terraform apply -var="web_instance_type=t3.large" -var="backend_instance_type=t2.large"

## Assumptions
- This architecture designed for non-prod photo online editor web application.
- EC2 backend instances require more compute power due to AI/image processing task
- AWS user was granted enough privilege to create role and assign policy

