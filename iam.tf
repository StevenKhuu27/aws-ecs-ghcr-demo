# IAM - two roles:
#   1. The EC2 *instance* role: lets the host register into the ECS cluster.
#   2. The ECS *task execution* role: lets ECS pull the image + read the GHCR
#      secret + write logs.

# ---- 1. EC2 instance role ----------------------------------------------------

# Role assumed by the EC2 host (principal: ec2.amazonaws.com).
resource "aws_iam_role" "ec2_instance" {
  # TODO: name, assume_role_policy (trust ec2.amazonaws.com)
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AWS-managed policy that grants the ECS agent what it needs.
resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Instance profile wrapping the role (this is what the launch template references).
resource "aws_iam_instance_profile" "ecs_instance" {
  name = "ecs-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name
}

# ---- 2. ECS task execution role ----------------------------------------------

# Role assumed by ECS to set up the task (principal: ecs-tasks.amazonaws.com).
resource "aws_iam_role" "task_execution" {
  name = "ecs-project-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# AWS-managed execution policy (pull from ECR, write logs, etc.).
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy so the execution role can read the GHCR creds from Secrets Manager.
# resource "aws_iam_role_policy" "task_execution_secrets" {
#  role = aws_iam_role.task_execution.id
#  Must add allowing secretsmanager:GetSecretValue on aws_secretsmanager_secret.ghcr.arn
# }
