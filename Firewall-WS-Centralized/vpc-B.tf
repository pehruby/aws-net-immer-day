# Create a VPC
resource "aws_vpc" "VPC_B" {
  cidr_block = "10.2.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "AnfwDemo-SpokeVPCB"
  }
}

resource "aws_subnet" "VPC_B_wl_sn_b" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AnfwDemo-SpokeVPCB-WorkloadSubnetB"
  }
}

resource "aws_subnet" "VPC_B_tgw_sn_b" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.2.0.0/28"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AnfwDemo-SpokeVPCB-TGWSubnetB"
  }
}

resource "aws_security_group" "VPC_B_sg_sn_B" {
  vpc_id = aws_vpc.VPC_B.id
  name = "AnfwDemo-SpokeVPCB-WorkloadSubnetB-Sg"
  description = "ICMP acess from 10.0.0.0/8"

  
  tags = {
    Name = "AnfwDemo-SpokeVPCB-WorkloadSubnetB-Sg"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_sn_B_ingress_1" {
  security_group_id = aws_security_group.VPC_B_sg_sn_B.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}



resource "aws_vpc_security_group_egress_rule" "sg_sn_B_egress_1" {
  security_group_id = aws_security_group.VPC_B_sg_sn_B.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# RT for workload subnet B
resource "aws_route_table" "VPC_B_wl_b" {
  vpc_id = aws_vpc.VPC_B.id


  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  }

  tags = {
    Name = "AnfwDemo-SpokeVPCB-WorkloadRouteTable"
  }
}

# Assoc VPC B workload RT to workload SN
resource "aws_route_table_association" "VPC_B_wl_rt_to_b" {
  subnet_id      = aws_subnet.VPC_B_wl_sn_b.id
  route_table_id = aws_route_table.VPC_B_wl_b.id
}

# RT for TGW subnet B
resource "aws_route_table" "VPC_B_tgw_b" {
  vpc_id = aws_vpc.VPC_B.id


  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  }

  tags = {
    Name = "AnfwDemo-SpokeVPCB-TGWRouteTableb"
  }
}

# Assoc VPC B TGW RT to TGW SN
resource "aws_route_table_association" "VPC_B_tgw_rt_to_b" {
  subnet_id      = aws_subnet.VPC_B_tgw_sn_b.id
  route_table_id = aws_route_table.VPC_B_tgw_b.id
}

