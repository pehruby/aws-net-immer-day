resource "aws_iam_role" "op_ec2_role" {
  name = "NetworkingWorkshopEC2Role"
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

resource "aws_iam_instance_profile" "op_server_ias_profile" {
  name = "OnPrem_server_ias_profile"
  role = "${aws_iam_role.op_ec2_role.name}"
}