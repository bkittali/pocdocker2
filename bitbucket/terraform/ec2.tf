resource "aws_instance" "jenkins_server" {
  ami           = "ami-001eed247d2135475"  # Replace with valid AMI ID
  instance_type = "t3.medium"
  key_name      = "won_ls_key"  # Replace with your SSH key name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id = aws_subnet.public_subnet_1.id  # Explicitly specify a VPC subnet

user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker

              # Create Jenkins Home and Seed Job Script Directory
              mkdir -p /var/jenkins_home/jobs/MyPipelineJob
              mkdir -p /var/jenkins_home/init.groovy.d

              # Set correct permissions for Jenkins to write inside the container
              chown -R 1000:1000 /var/jenkins_home
              chmod -R 775 /var/jenkins_home

              # Copy Jenkinsfile from terraform-provisioned location
              cat << 'EOT' > /var/jenkins_home/jobs/MyPipelineJob/Jenkinsfile
              $(cat jenkins/Jenkinsfile)
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
