resource "aws_ecs_cluster" "my_cluster" {
  name = "my-app-cluster"
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-app"
  container_definitions = jsonencode([
    {
      name  = "php"
      image = "1234567890.dkr.ecr.us-east-1.amazonaws.com/php-latest"
      memory = 512
      cpu = 256
      essential = true
    },
    {
      name  = "nginx"
      image = "1234567890.dkr.ecr.us-east-1.amazonaws.com/nginx-latest"
      memory = 512
      cpu = 256
      essential = true
    }
  ])
}

resource "aws_ecs_service" "my_service" {
  name            = "my-app-service"
  cluster        = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 2
  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "nginx"
    container_port   = 80
  }
}
