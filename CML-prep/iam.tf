# User group
resource "aws_iam_group" "cmlterraform" {
  name = "cmlterraform"
  path = "/"
}

/*
import {
  to = aws_iam_group_policy.s3_access_policy
  id = "group_of_mypolicy_name:mypolicy_name"
}
*/

# IAM policy for user group cmlterraform
# in video AmazonEC2FullAccess policy is also used as policy wich is passed to EC2 instance so that EC2 instance has  used
# used to read from cmlterraform bucket where CML images are stored

/*
# This create inline policy, bellow attached policy is also used as policy wich is passed to EC2 instance so that EC2 instance has  used
resource "aws_iam_group_policy" "s3_access_policy" {
  name  = "s3_access_policy"
  group = aws_iam_group.cmlterraform.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            Sid = "VisualEditor0",
            Effect = "Allow",
            Action = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            Resource = [
                "arn:aws:s3:::cmlterraform",
                "arn:aws:s3:::cmlterraform/*"
            ]
        },
    ]   
  })
}

*/
# Policy that specifies that users in this group can pass the role to the EC2 instance
# Will be attaced to user group
# Policy restric the access to our S3 bucket only
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

# Policy which allows access to bucket
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


# import ARN for predefined AmazonEC2FullAccess policy
# Provides full access to Amazon EC2 via the AWS Management Console.
data "aws_iam_policy" "ec2fullaccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# import ARN for predefined AmazonEC2FullAccess policy
# Provides full access to Amazon EC2 via the AWS Management Console.
data "aws_iam_policy" "ssmaccess" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

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

/*
# This role will probably allow EC2 instance to access files in S3 bucket
resource "aws_iam_role" "s3accessforec2" {
  name = "s3-access-for-ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cmlterraformpolicy" {
  role       = aws_iam_role.s3accessforec2.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
*/


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

# This role will allow EC2 instance access files in S3 bucket
# (on my behalf, see bellow policy attachment)
# The policy, or maybe instance profile (bellow) will be associated with EC2 instance when is also used as policy wich is passed to EC2 instance so that EC2 instance has  created
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

# Role will have access to S3 bucket on my behalf
resource "aws_iam_role_policy_attachment" "cmlterraformpolicy" {
  role       = aws_iam_role.s3accessforec2.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Role will have access to SSM (on my behalf ?)
resource "aws_iam_role_policy_attachment" "cmlterraformpolicy2" {
  role       = aws_iam_role.s3accessforec2.name
  policy_arn = data.aws_iam_policy.ssmaccess.arn
}

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