resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity     = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_subnet.id]
}
