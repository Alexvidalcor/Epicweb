# ----------------------------------------------
# Master Node Role
# ----------------------------------------------

resource "aws_iam_role" "k8s_iam-role1" {
  name = "ssm_full_access"
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

resource "aws_iam_role_policy_attachment" "k8s_iam-attachment1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  role       = aws_iam_role.k8s_iam-role1.name
}

resource "aws_iam_instance_profile" "k8s_iam-profile1" {
  name = "ssm_full_access"
  role = aws_iam_role.k8s_iam-attachment1.name
}

# ----------------------------------------------
# ----------------------------------------------