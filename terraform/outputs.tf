output "jenkins_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

#output "app_server_public_ip" {
#  value = aws_instance.ecs_instance.public_ip
#}
