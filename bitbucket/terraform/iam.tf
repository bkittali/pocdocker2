resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2-S3-Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_only" {
  name        = "S3ReadOnlyPolicy"
  description = "Allow EC2 to read from S3"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::won-ls-key/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_attach_s3" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

resource "aws_iam_policy" "secretsmanager_read" {
  name        = "SecretsManagerRead"
  description = "Allows EC2 to read AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = "arn:aws:secretsmanager:us-east-1:123456789012:secret:jenkins-aws-keys"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.jenkins_ec2_role.name
}