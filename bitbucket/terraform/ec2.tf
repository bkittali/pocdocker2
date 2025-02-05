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
              docker run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}
