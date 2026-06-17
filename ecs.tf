# ECS-on-EC2 - the core of the deploy.
# Flow: ASG launches a t3.micro from the ECS-optimised AMI -> host registers into
# the cluster -> the service schedules the task onto it -> the task runs your image.

# Latest ECS-optimised Amazon Linux 2023 AMI
data "aws_ssm_parameter" "ecs_ami" {
  # TODO: name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}
# aws ssm get-parameters-by-path \
#     --path /aws/service/ami-amazon-linux-latest \
#     --query 'Parameters[].Name'

# aws ssm get-parameters \
#     --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended

# The ECS cluster.
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
}

# Launch template for the container host.
resource "aws_launch_template" "ecs_host" {
  name          = "${var.project}-host"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.micro"

  # t3 is burstable: pin "standard" mode
  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }
  vpc_security_group_ids = [aws_security_group.ecs_host.id]
  user_data              = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config\n")
}

# One-instance Auto Scaling Group across the default subnets.
resource "aws_autoscaling_group" "ecs_host" {
  name                = "${var.project}-asg"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  launch_template {
    id      = aws_launch_template.ecs_host.id
    version = "$Latest"
  }
}

# CloudWatch log group for the container's stdout/stderr.
resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.project}-ecs-cloudwatch"
  retention_in_days = 1
}

# Task definition - what container to run and how.
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-app"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  cpu                      = 256
  memory                   = 256

  container_definitions = jsonencode([
    {
      name      = "yt-dlp"
      image     = var.container_image
      cpu       = 256
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "yt-dlp"
        }
      }
    }
  ])
}

# Service - keeps one copy of the task running on the cluster.
resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "EC2"
}
