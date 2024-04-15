
resource "aws_instance" "web_A" {
  ami           = "ami-0bd01824d64912730"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.server.name
  vpc_security_group_ids = [ aws_security_group.VPC_C_sg_web.id ]
  subnet_id   = aws_subnet.VPC_C_pri_a.id
  user_data_replace_on_change = true
  # associate_public_ip_address = true


  tags = {
    Name = "AnfwDemo-IngressVPC-WebInstanceA"
  }

  user_data = "${file("user_data_weba.sh")}"
}

resource "aws_instance" "web_B" {
  ami           = "ami-0bd01824d64912730"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.server.name
  vpc_security_group_ids = [ aws_security_group.VPC_C_sg_web.id ]
  subnet_id   = aws_subnet.VPC_C_pri_b.id
  user_data_replace_on_change = true
  # associate_public_ip_address = true


  tags = {
    Name = "AnfwDemo-IngressVPC-WebInstanceB"
  }


  user_data = "${file("user_data_webb.sh")}"
}
