
resource "aws_security_group" "VPC_C_sg_server1" {
  vpc_id = aws_vpc.VPC_C.id
  name = "VPC A Security Group"
  description = "VPC A Security Group"

  
  tags = {
    Name = "VPC A Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "VPC_C_Server1_assoc_acl_pubaallow_icmp_ipv4" {
  security_group_id = aws_security_group.VPC_C_sg_server1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "VPC_C_Server1_eg_traffic_ipv4" {
  security_group_id = aws_security_group.VPC_C_sg_server1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



resource "aws_instance" "VPC_C_pri_server" {
  ami           = "ami-0e731c8a588258d0d"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.server_ias_profile.name
  private_ip = "10.2.1.100"
  vpc_security_group_ids = [  aws_security_group.VPC_C_sg_server1.id]
  subnet_id   = aws_subnet.VPC_C_pri_sn_a.id


  tags = {
    Name = "VPC C Private AZ1 Server"
  }
}
