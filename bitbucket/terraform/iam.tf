# IAM Role for ECS Instance
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Instance Profile for ECS
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

############################
#FOR EC2 INSTANCE TYPE ONLY#
############################

# Step 1: Create IAM Role for EC2

resource "aws_iam_role" "ec2_role" {
  name = "EC2-S3-SecretsManager-Access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Step 2: Create IAM policies for S3 and secrets Manager

resource "aws_iam_policy" "s3_full_access" {
  name        = "S3FullAccessPolicy"
  description = "Allow EC2 to read/write from won-ls-key S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::won-ls-key",
          "arn:aws:s3:::won-ls-key/*"
        ]
      }
    ]
  })
}

# AWS Secrets Manager Ready Only Access

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

# Step 3: Attach Policies to IAM Role

# Attach S3 Full Access Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "attach_s3_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_full_access.arn
}

# Attach Secrets Manager Read Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "attach_secrets_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}

# Step 4: Create IAM Instance Profile for EC2

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}
