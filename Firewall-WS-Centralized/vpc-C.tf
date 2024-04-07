# Create a VPC
resource "aws_vpc" "VPC_C" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "AnfwDemo-InspectionVPC"
  }
}

# Internet GW
resource "aws_internet_gateway" "VPC_C_igw" {
  vpc_id = aws_vpc.VPC_C.id

  tags = {
    Name = "AnfwDemo-InspectionVPCC-IGW"
  }
}

# AZ A

# public IP for NAT
resource "aws_eip" "eip_natgw_a" {
  vpc = true
  tags = {
    Name = "NAT GW A IP"
  }
}

# NAT gateway connected to public subnet 
resource "aws_nat_gateway" "VPC_C_natgw_a" {
  allocation_id = aws_eip.eip_natgw_a.id
  subnet_id     = aws_subnet.VPC_C_pub_a.id

  tags = {
    Name = "AnfwDemo-InspectionVPCC-NATGWA"
  }

}


resource "aws_subnet" "VPC_C_tgw_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.16.0/28"
  availability_zone = "us-east-1a"

  tags = {
    Name = "AnfwDemo-InspectionVPCC-TGWSubnetA"
  }
}

resource "aws_subnet" "VPC_C_fw_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.16.32/28"
  availability_zone = "us-east-1a"

  tags = {
    Name = "AnfwDemo-InspectionVPCC-FirewallSubnetA"
  }
}

resource "aws_subnet" "VPC_C_pub_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "AnfwDemo-InspectionVPCC-PublicSubnetA"
  }
}

resource "aws_subnet" "VPC_C_elb_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "AnfwDemo-InspectionVPCC-ELBSubnetA"
  }
}

resource "aws_subnet" "VPC_C_wl_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "AnfwDemo-InspectionVPCC-WorkloadSubnetA"
  }
}

# RT for TGW subnet C
resource "aws_route_table" "VPC_C_tgw_a" {
  vpc_id = aws_vpc.VPC_C.id
  depends_on = [ aws_networkfirewall_firewall.central ]


  route {
    # tmp
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.central.firewall_status[0].sync_states): ss.attachment[0].endpoint_id if ss.availability_zone == "us-east-1a"],0)
    #nat_gateway_id = aws_nat_gateway.VPC_C_natgw_a.id
    # inspection FW
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-TGWRouteTableA"
  }
}

# Assoc VPC C TGW RT to TGW SN
resource "aws_route_table_association" "VPC_C_tgw_rt_to_a" {
  subnet_id      = aws_subnet.VPC_C_tgw_a.id
  route_table_id = aws_route_table.VPC_C_tgw_a.id
}

# RT for FW subnet C
resource "aws_route_table" "VPC_C_fw_a" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_C_natgw_a.id
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-FirewallRouteTableA"
  }
}

# Assoc VPC C FW RT to FW SN
resource "aws_route_table_association" "VPC_C_fw_rt_to_a" {
  subnet_id      = aws_subnet.VPC_C_fw_a.id
  route_table_id = aws_route_table.VPC_C_fw_a.id
}

# RT for public subnet C
resource "aws_route_table" "VPC_C_pub_a" {
  vpc_id = aws_vpc.VPC_C.id
  depends_on = [ aws_networkfirewall_firewall.central ]


  # tmp
  route {
    cidr_block = "10.0.0.0/8"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.central.firewall_status[0].sync_states): ss.attachment[0].endpoint_id if ss.availability_zone == "us-east-1a"],0)
    #transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_C_igw.id
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-PublicRouteTableA"
  }
}

# Assoc VPC C public RT to public SN
resource "aws_route_table_association" "VPC_C_pub_rt_to_a" {
  subnet_id      = aws_subnet.VPC_C_pub_a.id
  route_table_id = aws_route_table.VPC_C_pub_a.id
}

/*
# RT for ELB subnet C
resource "aws_route_table" "VPC_C_elb_a" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "0.0.0.0/0"
    # inspection FW
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-ELBRouteTableA"
  }
}

# Assoc VPC C ELB RT to ELB SN
resource "aws_route_table_association" "VPC_C_elb_rt_to_a" {
  subnet_id      = aws_subnet.VPC_C_elb_a.id
  route_table_id = aws_route_table.VPC_C_elb_a.id
}
*/
# RT for workload subnet C
resource "aws_route_table" "VPC_C_wl_a" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_C_natgw_a.id
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-WorkloadRouteTableA"
  }
}

# Assoc VPC C workload RT to workload SN
resource "aws_route_table_association" "VPC_C_wl_rt_to_a" {
  subnet_id      = aws_subnet.VPC_C_wl_a.id
  route_table_id = aws_route_table.VPC_C_wl_a.id
}

# AZ B

# public IP for NAT
resource "aws_eip" "eip_natgw_b" {
  vpc = true
  tags = {
    Name = "NAT GW B IP"
  }
}

# NAT gateway connected to public subnet 
resource "aws_nat_gateway" "VPC_C_natgw_b" {
  allocation_id = aws_eip.eip_natgw_b.id
  subnet_id     = aws_subnet.VPC_C_pub_b.id

  tags = {
    Name = "AnfwDemo-InspectionVPCC-NATGWB"
  }

}


resource "aws_subnet" "VPC_C_tgw_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.16.16/28"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AnfwDemo-InspectionVPCC-TGWSubnetB"
  }
}

resource "aws_subnet" "VPC_C_fw_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.16.48/28"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AnfwDemo-InspectionVPCC-FirewallSubnetB"
  }
}

resource "aws_subnet" "VPC_C_pub_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "AnfwDemo-InspectionVPCC-PublicSubnetB"
  }
}

resource "aws_subnet" "VPC_C_elb_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "AnfwDemo-InspectionVPCC-ELBSubnetB"
  }
}

resource "aws_subnet" "VPC_C_wl_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AnfwDemo-InspectionVPCC-WorkloadSubnetB"
  }
}

# RT for TGW subnet C
resource "aws_route_table" "VPC_C_tgw_b" {
  vpc_id = aws_vpc.VPC_C.id
  depends_on = [ aws_networkfirewall_firewall.central ]

  route {
    # tmp
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.central.firewall_status[0].sync_states): ss.attachment[0].endpoint_id if ss.availability_zone == "us-east-1b"],0)
    # nat_gateway_id = aws_nat_gateway.VPC_C_natgw_b.id
    # inspection FW
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-TGWRouteTableA"
  }
}

/*
# module.vpc.aws_networkfirewall_firewall.default:
resource "aws_networkfirewall_firewall" "default" {
    arn                               = "arn:aws:network-firewall:ap-south-1:XXXXXXXXXXXX:firewall/example-dev-mb-network-firewall"
    delete_protection                 = false
    firewall_policy_arn               = "arn:aws:network-firewall:ap-south-1:XXXXXXXXXXX:firewall-policy/example-dev-mb-network-firewall-policy"
    firewall_policy_change_protection = false
    firewall_status                   = [
        {
            sync_states = [
                {
                    attachment        = [
                        {
                            endpoint_id = "vpce-031ed3c5d848"
                            subnet_id   = "subnet-0b6782fac271"
                        },
                    ]
                    availability_zone = "ap-south-1b"
                },
                {
                    attachment        = [
                        {
                            endpoint_id = "vpce-044aa97a9fb8"
                            subnet_id   = "subnet-032b155aadf6"
                        },
                    ]
                    availability_zone = "ap-south-1a"
                },
                {
                    attachment        = [
                        {
                            endpoint_id = "vpce-0a77b53c9bd7"
                            subnet_id   = "subnet-03472e827cc0"
                        },
                    ]
                    availability_zone = "ap-south-1c"
                },
            ]
        },
    ]
    id                                = "arn:aws:network-firewall:ap-south-1:XXXXXXXXXXXX:firewall/example-dev-mb-network-firewall"
    name                              = "example-dev-mb-network-firewall"
    subnet_change_protection          = false
    tags                              = {
        "Name" = "example-dev-mb-network-firewall"
    }
    tags_all                          = {
        "Name" = "example-dev-mb-network-firewall"
    }
    update_token                      = "a9e4b5ae-c0c9-4974-aa7d-fc29aae"
    vpc_id                            = "vpc-07784e76834e"

    subnet_mapping {
        ip_address_type = "IPV4"
        subnet_id       = "subnet-032b155aadf6"
    }
    subnet_mapping {
        ip_address_type = "IPV4"
        subnet_id       = "subnet-03472e827cc0"
    }
    subnet_mapping {
        ip_address_type = "IPV4"
        subnet_id       = "subnet-0b6782fac271"
    }
}
*/


# Assoc VPC C TGW RT to TGW SN
resource "aws_route_table_association" "VPC_C_tgw_rt_to_b" {
  subnet_id      = aws_subnet.VPC_C_tgw_b.id
  route_table_id = aws_route_table.VPC_C_tgw_b.id
}

# RT for FW subnet C
resource "aws_route_table" "VPC_C_fw_b" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_C_natgw_b.id
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-FirewallRouteTableB"
  }
}

# Assoc VPC C FW RT to FW SN
resource "aws_route_table_association" "VPC_C_fw_rt_to_b" {
  subnet_id      = aws_subnet.VPC_C_fw_b.id
  route_table_id = aws_route_table.VPC_C_fw_b.id
}

# RT for public subnet C
resource "aws_route_table" "VPC_C_pub_b" {
  vpc_id = aws_vpc.VPC_C.id

  depends_on = [ aws_networkfirewall_firewall.central ]


  # tmp
  route {
    cidr_block = "10.0.0.0/8"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.central.firewall_status[0].sync_states): ss.attachment[0].endpoint_id if ss.availability_zone == "us-east-1b"],0)
    #transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_C_igw.id
  }

  tags = {
    Name = "AnfwDemo-InspectionVPCC-PublicRouteTableA"
  }
}

# Assoc VPC C public RT to public SN
resource "aws_route_table_association" "VPC_C_pub_rt_to_b" {
  subnet_id      = aws_subnet.VPC_C_pub_b.id
  route_table_id = aws_route_table.VPC_C_pub_b.id
}



resource "aws_security_group" "VPC_C_sg_sn_C" {
  vpc_id = aws_vpc.VPC_C.id
  name = "AnfwDemo-InspectionVPCC-FtpServerInstance-Sg"
  description = "FtpServerInstnaceSecurityGroup"

  
  tags = {
    Name = "AnfwDemo-InspectionVPCC-FtpServerInstance-Sg"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_sn_C_ingress_1" {
  security_group_id = aws_security_group.VPC_C_sg_sn_C.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "sg_sn_C_ingress_2" {
  security_group_id = aws_security_group.VPC_C_sg_sn_C.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 64000
  ip_protocol       = "tcp"
  to_port           = 64001
}


resource "aws_vpc_security_group_egress_rule" "sg_sn_C_egress_1" {
  security_group_id = aws_security_group.VPC_C_sg_sn_C.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


