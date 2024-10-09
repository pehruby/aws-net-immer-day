### Create groups

# User group
resource "aws_iam_group" "cmlterraform" {
  name = "cmlterraform"
  path = "/"
}

### Create user

# Probably we will have to create access keys in GUI for the user ?
resource "aws_iam_user" "cml_terraform" {
  name = "cml_terraform"
  path = "/"

  tags = {
    tag-key = "cml_terraform"
  }
}

# associate the user with user group
resource "aws_iam_user_group_membership" "cml_terraform" {
  user = aws_iam_user.cml_terraform.name

  groups = [
    aws_iam_group.cmlterraform.name,
  ]
}

#### Create policies

# Create inline policy and attach it to  cml_terraform group
# Policy that specifies that users in this group can pass the role s3-access-for-ec2
resource "aws_iam_group_policy" "cmlterraform_inline_passrole" {
  name  = "pass-role"
  group = aws_iam_group.cmlterraform.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "VisualEditor0",
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.s3accessforec2.arn
      },
    ]
  })
}

# Customer managed policy which allows access to bucket
# Will be attached to user group
# It is also used as policy which is passed to EC2 instance so that EC2 instance has access rights to access S3 the same way as terraform user
resource "aws_iam_policy" "s3_access_policy" {
  name        = "cml-s3-access"
  path        = "/"
  description = "cml-s3-access"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::phcmlimages",
          "arn:aws:s3:::phcmlimages/*"
        ]
      },
    ]
  })
}


# import ARN for predefined (AWS managed) AmazonEC2FullAccess policy
# Provides full access to Amazon EC2 via the AWS Management Console.
data "aws_iam_policy" "ec2fullaccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# import ARN for predefined (AWS managed) AmazonSSMManagedInstanceCore policy
# Provides access to Amazon SSM service (used for EC2 instance)
data "aws_iam_policy" "ssmaccess" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


#### Attach policies to cml_terraform group


# Attach AmazonEC2FullAccess policy to cmlterraform group
# User Group will have full access to EC2.
resource "aws_iam_group_policy_attachment" "cml_attach_s3full" {
  group      = aws_iam_group.cmlterraform.name
  policy_arn = data.aws_iam_policy.ec2fullaccess.arn
}

# Attach CML terraform policy to cmlterraform group
# User group will have access to our S3 bucket, where images will be stored
resource "aws_iam_group_policy_attachment" "cml_attach_cml_pol" {
  group      = aws_iam_group.cmlterraform.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


#### Create role 

# Trust relationship for role s3-access-for-ec2
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create role s3-access-for-ec2. The role can be assumed (used) by EC2 service only
# EC2 instance will be able to access specific S3 bucket and SSM service
resource "aws_iam_role" "s3accessforec2" {
  name               = "s3-access-for-ec2"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}



# Not sure what is also used as policy wich is passed to EC2 instance so that EC2 instance has  relationship between role and instance profile
# Instance profile ARN is also used as policy wich is passed to EC2 instance so that EC2 instance has  visible inside role in AWS GUI
resource "aws_iam_instance_profile" "s3accessforec2" {
  name = "s3-access-for-ec2"
  role = aws_iam_role.s3accessforec2.name
}

#### Attach policies to the role s3-access-for-ec2

# Role s3-access-for-ec2 will have access to S3 bucket 
resource "aws_iam_role_policy_attachment" "cmlterraformpolicy" {
  role       = aws_iam_role.s3accessforec2.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Role s3-access-for-ec2 will have access to SSM 
resource "aws_iam_role_policy_attachment" "cmlterraformpolicy2" {
  role       = aws_iam_role.s3accessforec2.name
  policy_arn = data.aws_iam_policy.ssmaccess.arn
}
