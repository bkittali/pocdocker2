resource "aws_instance" "jenkins_server" {
  ami           = "ami-12345678"  # Replace with valid AMI ID
  instance_type = "t3.medium"
  key_name      = "your-key"  # Replace with your SSH key name
  security_groups = [aws_security_group.ecs_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker
              docker run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-12345678"  # Replace with valid AMI ID
  instance_type = "t3.medium"
  key_name      = "your-key"  # Replace with your SSH key name
  security_groups = [aws_security_group.ecs_sg.id]

  tags = {
    Name = "App-Server"
  }
}
