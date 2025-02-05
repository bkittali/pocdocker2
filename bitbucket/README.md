# 🚀 Deployable Application - CI/CD with AWS EC2, Terraform, Jenkins & Ansible (No S3)

This project automates the deployment of a **PHP, Nginx, MySQL, and Tomcat** application using **AWS EC2-based Docker containers**, **Terraform**, **Ansible**, and **Jenkins**. Developers' latest code is deployed **directly from Bitbucket to new app containers using Docker images** (No S3).

## **🔹 Infrastructure Overview**

The deployment consists of:
- **AWS EC2 Instances**: Hosts Jenkins and application containers.
- **AWS ECR**: Stores Docker images.
- **AWS Application Load Balancer (ALB)**: Routes traffic to application containers.
- **Terraform**: Provisions AWS infrastructure (VPC, EC2 instances, ALB, Security Groups).
- **Jenkins**: Runs inside a Docker container on an EC2 instance to automate CI/CD.
- **Ansible**: Deploys updated containers using Blue-Green deployment.
- **Docker Images**: Built and stored in ECR and used for new containers.

## **📌 Project Directory Structure**
```
/project-root
 ├── app/                     # PHP application files
 │   ├── index.php
 │   ├── config.php
 │   ├── Dockerfile
 │
 ├── tomcat/                  # Tomcat WAR deployment
 │   ├── myapp.war
 │   ├── Dockerfile
 │
 ├── nginx/                   # Nginx reverse proxy
 │   ├── default.conf
 │   ├── Dockerfile
 │
 ├── mysql/                   # MySQL database
 │   ├── init.sql
 │   ├── Dockerfile
 │
 ├── terraform/               # Infrastructure as Code
 │   ├── vpc.tf               # VPC and Subnets
 │   ├── security_groups.tf   # Security Groups
 │   ├── alb.tf               # Application Load Balancer
 │   ├── ec2.tf               # EC2 Instances and Load Balancer Target Groups
 │   ├── outputs.tf           # Output values
 │   ├── variables.tf         # Variables for Terraform
 │   ├── providers.tf         # Terraform AWS provider
 │
 ├── ansible/                 # Ansible Playbooks
 │   ├── inventory.ini        # List of EC2 instances
 │   ├── deploy-containers.yml # Deploy Docker containers on EC2
 │   ├── blue-green-deploy.yml # Perform Blue-Green deployment
 │
 ├── jenkins/                 # Jenkins setup
 │   ├── Jenkinsfile          # Jenkins pipeline script
 │   ├── docker-compose.yml   # Jenkins setup inside a container
 │
 ├── docker-compose.yml       # Docker Compose setup for all services
 ├── README.md                # Documentation
```

## **🔹 Step 1: Set Up Infrastructure using Terraform**
```sh
cd terraform
terraform init
terraform apply -auto-approve
```

## **🔹 Step 2: Start Jenkins on EC2 Instance**
```sh
ssh -i your-key.pem ec2-user@<JENKINS_EC2_IP>
docker-compose -f jenkins/docker-compose.yml up -d
```

## **🔹 Step 3: CI/CD Pipeline Overview**
| **Stage** | **Tool** | **Description** |
|-----------|---------|----------------|
| **1. Code Commit** | Bitbucket | Developers push code to the repo |
| **2. Jenkins Trigger** | Jenkins (in container) | Bitbucket Webhook triggers Jenkins Pipeline |
| **3. Fetch Latest Code** | Git | Jenkins pulls the latest codebase from Bitbucket |
| **4. Build & Test** | Docker & Docker Compose | Jenkins builds Docker images for PHP, Nginx, Tomcat |
| **5. Push to ECR** | AWS CLI | Docker images are stored in AWS ECR |
| **6. Deploy to AWS EC2** | Ansible + Docker | Ansible deploys the latest Docker images to EC2-based containers |
| **7. Blue-Green Switching** | Load Balancer | Switches traffic with zero downtime |

## **🔹 Step 4: Deploy Updated Application Using Ansible**
```sh
ansible-playbook -i ansible/inventory.ini ansible/deploy-containers.yml
```

## **🔹 Step 5: Perform Blue-Green Deployment**
```sh
ansible-playbook -i ansible/inventory.ini ansible/blue-green-deploy.yml
```

## **🔹 Jenkinsfile for Automating Deployment**
```groovy
pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID = 'your-aws-account-id'
        AWS_REGION = 'us-east-1'
        ECR_REPO = 'your-ecr-repository'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'git@bitbucket.org:yourrepo.git'
            }
        }
        stage('Build and Push Images') {
            steps {
                sh '''
                docker build -t php-app:latest ./app
                docker build -t nginx-server:latest ./nginx
                docker build -t mysql-db:latest ./mysql
                docker build -t tomcat-server:latest ./tomcat

                aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                
                docker tag php-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:php-latest
                docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:php-latest
                '''
            }
        }
        stage('Deploy to EC2') {
            steps {
                sh '''
                ansible-playbook -i ansible/inventory.ini ansible/deploy-containers.yml
                '''
            }
        }
        stage('Perform Blue-Green Deployment') {
            steps {
                sh '''
                ansible-playbook -i ansible/inventory.ini ansible/blue-green-deploy.yml
                '''
            }
        }
    }
}
```

## **🚀 Summary**
- **Jenkins runs in a Docker container on EC2** to manage CI/CD.
- **Ansible deploys Docker images to EC2-based containers**.
- **Bitbucket webhook triggers new builds and deployments automatically**.
- **Blue-Green Deployment ensures zero downtime**.
- **AWS ECR stores Docker images**, and updates are deployed from Jenkins.

🚀 **Run `terraform apply`, start Jenkins, and deploy using Ansible!**

---
