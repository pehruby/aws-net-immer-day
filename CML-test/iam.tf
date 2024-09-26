

resource "aws_iam_role" "ec2_role" {
  name = "NetworkingWorkshopEC2Role2"
  path = "/"
  managed_policy_arns = [ "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/AmazonS3FullAccess"]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "server_ias_profile" {
  name = "server_ias_profile"
  role = "${aws_iam_role.ec2_role.name}"
}



