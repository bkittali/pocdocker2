resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "ecs-launch-template"
  image_id      = "ami-001eed247d2135475"  # Replace with your correct AMI ID
  instance_type = "t3.medium"
  key_name      = "won_ls_key"  # Replace with your SSH key name


  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }


  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_sg.id]
  }


  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.my_cluster.name}" >> /etc/ecs/ecs.config
              systemctl enable --now ecs
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ECS-Instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity     = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]  # Use both subnets


  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ECS-ASG-Instance"
    propagate_at_launch = true
  }
}
