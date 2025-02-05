resource "aws_instance" "jenkins_server" {
  ami           = "ami-001eed247d2135475"  # Replace with valid AMI ID

  instance_type = "t3.medium"
  key_name      = "won_ls_key"  # Replace with your SSH key name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id = aws_subnet.public_subnet_1.id  # Explicitly specify a VPC subnet

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cli jq
              yum install -y docker git
              systemctl start docker
              systemctl enable docker

              # Retrieve AWS credentials from Secrets Manager
              CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id jenkins-aws-keys --query SecretString --output text)

              # Parse and set AWS credentials
              AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r .AWS_ACCESS_KEY_ID)
              AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r .AWS_SECRET_ACCESS_KEY)

              # Create AWS credentials file
              mkdir -p ~/.aws
              cat <<EOT > ~/.aws/credentials
              [default]
              region = us-east-1
              aws_access_key_id = $AWS_ACCESS_KEY_ID
              aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
              EOT
              chmod 600 ~/.aws/credentials

              # Verify Secrets Manager Access
              aws secretsmanager get-secret-value --secret-id jenkins-aws-keys
              # Create SSH directory for Jenkins securely
              mkdir -p /var/jenkins_home/.ssh
              chmod 700 /var/jenkins_home/.ssh

              # Securely Retrieve the SSH Private Key (Method 1: From S3)
              aws s3 cp s3://won-ls-key/won_ls_key.pem /var/jenkins_home/.ssh/id_rsa
              
              # Alternative: Retrieve from AWS Secrets Manager (Method 2)
              # aws secretsmanager get-secret-value --secret-id won_ls_key --query SecretString --output text > /var/jenkins_home/.ssh/id_rsa

              # Set secure permissions for SSH key
              chown -R 1000:1000 /var/jenkins_home/.ssh
              chmod 600 /var/jenkins_home/.ssh/id_rsa

              # Add GitHub to known hosts to avoid prompt during first-time connection
              ssh-keyscan -t rsa github.com > /var/jenkins_home/.ssh/known_hosts
              chmod 644 /var/jenkins_home/.ssh/known_hosts

              # Start SSH Agent and add key (for Jenkins to use GitHub)
              eval "$(ssh-agent -s)"
              ssh-add /var/jenkins_home/.ssh/id_rsa

              #Clone github repository
              git clone git@github.com:bkittali/pocdocker2.git

              # Create Jenkins Home and Seed Job Script Directory
              mkdir -p /var/jenkins_home/jobs/MyPipelineJob
              mkdir -p /var/jenkins_home/init.groovy.d

              # Set correct permissions for Jenkins to write inside the container
              chown -R 1000:1000 /var/jenkins_home
              chmod -R 775 /var/jenkins_home

              # Copy Jenkinsfile from terraform-provisioned location
              cat << 'EOT' > /var/jenkins_home/jobs/MyPipelineJob/Jenkinsfile
              $(cat "pocdocker/jenkins/Jenkinsfile")
              EOT

              # Jenkins Groovy Script to Create a Pipeline Job
              cat << 'EOT' > /var/jenkins_home/init.groovy.d/seedJob.groovy
              import jenkins.model.*
              import hudson.model.*
              import org.jenkinsci.plugins.workflow.job.WorkflowJob
              import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

              def jenkins = Jenkins.instance
              def jobName = "MyPipelineJob"

              if (jenkins.getItem(jobName) == null) {
                  def job = jenkins.createProject(WorkflowJob, jobName)
                  def script = new File("/var/jenkins_home/jobs/MyPipelineJob/Jenkinsfile").text
                  job.setDefinition(new CpsFlowDefinition(script, true))
                  job.save()
                  println "Jenkins job 'MyPipelineJob' created successfully!"
              } else {
                  println "Jenkins job 'MyPipelineJob' already exists. Skipping creation."
              }
              EOT

              # Ensure Jenkins container runs as user 1000 to avoid permission issues
              docker run -d -p 8080:8080 -p 50000:50000 \
                --name jenkins \
                -u 1000:1000 \
                -v /var/jenkins_home:/var/jenkins_home \
                -v /var/jenkins_home/init.groovy.d:/usr/share/jenkins/ref/init.groovy.d \
                jenkins/jenkins:lts
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}
