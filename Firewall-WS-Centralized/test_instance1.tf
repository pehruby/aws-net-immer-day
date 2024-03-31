# Spoke VPC A Test Instance 1 UserData is for:
# Lab 4 - Custome Suricata rules with Strict Rule ordering
# Lab 5 - Threat Hunting with AWS Network Firewall

resource "aws_instance" "sn_A_test" {
  ami           = "ami-0bd01824d64912730"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.server_ias_profile.name
  # private_ip = "172.16.0.100"
  # source/destination checking must be disabled on ENI !!!
  #source_dest_check = false
  vpc_security_group_ids = [ aws_security_group.VPC_A_sg_sn_A.id ]
  subnet_id   = aws_subnet.VPC_A_wl_sn_a.id
  # associate_public_ip_address = true


  tags = {
    Name = "AnfwDemo-SpokeVPCA-TestInstance1"
  }

  depends_on = [ aws_instance.ftp_server ]

  user_data = base64encode(templatefile("user_data_ti1.sh", {
        FtpServerInstance1SubnetCPrivateIp      = "${aws_instance.ftp_server.private_ip}"
      } ))
}
