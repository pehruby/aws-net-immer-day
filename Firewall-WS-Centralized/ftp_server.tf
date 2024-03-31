resource "aws_instance" "ftp_server" {
  ami           = "ami-0bd01824d64912730"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.server_ias_profile.name
  # private_ip = "172.16.0.100"
  #source_dest_check = false
  vpc_security_group_ids = [ aws_security_group.VPC_C_sg_sn_C.id ]
  subnet_id   = aws_subnet.VPC_C_pub_a.id
  associate_public_ip_address = true


  tags = {
    Name = "AnfwDemo-InspectionVPCC-FtpServerInstance1"
  }

  #depends_on = [ aws_instance.sn_C_ftp ]

  user_data = "${file("user_data_ftp.sh")}"
}