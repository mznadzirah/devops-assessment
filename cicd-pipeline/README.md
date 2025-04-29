# Challenge 4: CI/CD Pipeline Design
## Overview
This document proposes to have separate pipeline for *deployment* and *rollback*. Deployment job is meant for building a new application version while the rollback job allow user to use previous version when an application version rollback is required.

## Tools Selection

### 1. Version Control: Gitlab
- **Justification**:
- GitLab is ideal for companies that want to self-host their version control system. It offers GitLab CE (Community Edition) which is free to host on your own infrastructure.
- **Used for**: Store and manage source code and enabling collaboration among multiple developers.

### 2. Jenkins
- **Justification**: Jenkins is flexible to configure many type of pipelines to cater different purposes,
- **Used for**: Configure pipelines to automate code build, test, deployment and other jobs.

### 3. Sonarqube
- **Justification**: SonarQube analyzes code and generates detailed reports showing bugs, security vulnerabilities
- **Used for**: Scanning source code to improve quality and security through static analysis.

### 4. Maven
- **Justification**: Maven is a widely-used build automation tool for Java projects.
- **Used for**: 
- Compiling Java projects
- Running unit/integration tests via JUnit
- Packaging applications (JARs, WARs)

### 5. Docker
- **Justification**: Docker makes it easy to run the application in any environment by packaging everything it needs into one container
- **Used for**:
- Running the web application in a container.
- Ensuring it works the same on any machine.
- Simplifying deployment and testing.

### 6. AWS ECR
- **Justification**: Managed container image registry provided by AWS
- **Used for**: Store application docker images version

### 7. AWS EKS
- **Justification**: AWS's managed Kubernetes platform
- **Used for**: To host all deployed containerized applications

## Pipeline Stages
Stage 1: Build & Test
- Jenkins pulls the code and triggers a Maven build.
- Unit and integration tests run automatically.
- SonarQube scans the code for quality and security issues.

Stage 2: Build Docker Image
- Once tests pass, docker builds the application image.
docker build -t <your-app>:1.0.0 . 
- Tag the image with the build version
docker tag <your-app>:1.0.0 <aws_account_id>.dkr.ecr.<aws-region>.amazonaws.com/<your-app>:1.0.0

Stage 3: Authenticate and Push Image to AWS ECR
- Authenticate to AWS ECR
- Push the docker image to AWS ECR.
docker push <aws_account_id>.dkr.ecr.<aws-region>.amazonaws.com/<your-app>:1.0.0 

Stage 4: Scan Docker image
- Scan the new image version pushed to ECR
aws ecr start-image-scan --repository-name name --image-id imageTag=tag_name --region us-east-2
- Describe/display the result
aws ecr describe-image-scan-findings --repository-name name --image-id imageTag=tag_name --region us-east-2

Stage 5: Deployment to AWS EKS
- Kubernetes grab the build version and pass as parameter to update the deployment 


## Rollbacks Plan
**Create a rollback jenkins job**:
- When a user decides to roll back to a previous version, the rollback job will prompt for user input:
- The user must enter the desired version (e.g., 1.0.0-SNAPSHOT).
- This version refers to the image tag stored in AWS ECR.
- The deployment YAML file will be automatically updated with the specified image version
(by passing the parameter)
- Kubernetes will pull the specified image version from ECR and redeploy it.

## Security Considerations
- Protect main branch (restrict direct push to main)
- Review and approve code before merge to main
- Store all credential in Jenkins credential manager(never hardcode any credential in the pipeline's configuration)
- Perform Code scanning via integration with Sonarqube
- Execute docker image scanning in ECR

