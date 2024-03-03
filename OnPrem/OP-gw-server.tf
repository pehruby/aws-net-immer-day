
resource "aws_security_group" "VPC_OP_sg_gw_server" {
  vpc_id = aws_vpc.VPC_OP.id
  name = "On-Premises Customer Gateway Security Group"
  description = "Security group for Customer Gateway Server"

  
  tags = {
    Name = "On-Premises Customer Gateway Security Group"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress_1" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress_2" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "172.16.0.0/16"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress_3" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 500
  ip_protocol       = "udp"
  to_port           = 500
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress_4" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 4500
  ip_protocol       = "udp"
  to_port           = 4500
}

# Probably not needed ?
resource "aws_vpc_security_group_ingress_rule" "sg_ingress_5" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "54.236.23.229/32"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}



resource "aws_vpc_security_group_egress_rule" "VPC_OP_eg_traffic_ipv4" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


/*
resource "aws_network_interface" "iface_server1" {
  subnet_id   = aws_subnet.VPC_OP_pub_sn_b.id
  security_groups = [ aws_security_group.VPC_OP_sg_gw_server.id ]

  tags = {
    Name = "Interface for VPC A Public AZ2 Server"
  }
}
*/

# public IP for NAT
resource "aws_eip" "OP_server_eip" {
  vpc = true
  tags = {
    Name = "GW server public IP"
  }
}

# aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 
resource "aws_instance" "VPC_OP_pub_server" {
  ami           = "ami-014d544cfef21b42d"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.op_server_ias_profile.name
  private_ip = "172.16.0.100"
  vpc_security_group_ids = [ aws_security_group.VPC_OP_sg_gw_server.id ]
  subnet_id   = aws_subnet.VPC_OP_pub_sn_a.id
  associate_public_ip_address = true


  tags = {
    Name = "On-Premises Customer Gateway"
  }

  user_data = <<EOF1
#!/bin/bash

# install OpenSWAN
yum install -y openswan
systemctl enable ipsec.service

# Enable IP forwarding
cat >> /etc/sysctl.conf<< EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
EOF

sysctl -p
EOF1
}



/*
# Create an EIP
resource "aws_eip" "server1" {
  vpc = true
}


# Associate the EIP with the instance
resource "aws_eip_association" "server1" {
  instance_id   = aws_instance.VPC_OP_pub_server.id
  allocation_id = aws_eip.server1.id
}

*/

