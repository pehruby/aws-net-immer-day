# Create a VPC
resource "aws_vpc" "VPC_B" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "VPC B"
  }
}

resource "aws_subnet" "VPC_B_pub_sn_a" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.1.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC B Public Subnet AZ1"
  }
}

resource "aws_subnet" "VPC_B_pri_sn_a" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC B Private Subnet AZ1"
  }
}

resource "aws_subnet" "VPC_B_pub_sn_b" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "VPC B Public Subnet AZ2"
  }
}

resource "aws_subnet" "VPC_B_pri_sn_b" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.1.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "VPC B Private Subnet AZ2"
  }
}

# if no entries are specified, it is only default entry which denies all created
resource "aws_network_acl" "VPC_B_wls_acl" {
  vpc_id = aws_vpc.VPC_B.id

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "VPC B Workload Subnets NACL"
  }
}

# Associate ACL with all 4 subnets (private and public)
resource "aws_network_acl_association" "VPC_B_assoc_acl_puba" {
  network_acl_id = aws_network_acl.VPC_B_wls_acl.id
  subnet_id      = aws_subnet.VPC_B_pub_sn_a.id
}

resource "aws_network_acl_association" "VPC_B_assoc_acl_pria" {
  network_acl_id = aws_network_acl.VPC_B_wls_acl.id
  subnet_id      = aws_subnet.VPC_B_pri_sn_a.id
}

resource "aws_network_acl_association" "VPC_B_assoc_acl_pubb" {
  network_acl_id = aws_network_acl.VPC_B_wls_acl.id
  subnet_id      = aws_subnet.VPC_B_pub_sn_b.id
}

resource "aws_network_acl_association" "VPC_B_assoc_acl_prib" {
  network_acl_id = aws_network_acl.VPC_B_wls_acl.id
  subnet_id      = aws_subnet.VPC_B_pri_sn_b.id
}


# RT for public subnets
# by default only one enry which routes VPC range to local
resource "aws_route_table" "VPC_B_pub_rt" {
  vpc_id = aws_vpc.VPC_B.id

  # IGW defined bellow in the file
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_B_igw.id
  }

  tags = {
    Name = "VPC B Public Route Table"
  }
}

# RT for private subnets
resource "aws_route_table" "VPC_B_pri_rt" {
  vpc_id = aws_vpc.VPC_B.id

  # default route to NAT GW in public subnet
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_B_natgw.id
  }

  tags = {
    Name = "VPC B Private Route Table"
  }
}

# Assoc VPC B public RT to public SN AZ1
resource "aws_route_table_association" "VPC_B_pub_rt_to_a" {
  subnet_id      = aws_subnet.VPC_B_pub_sn_a.id
  route_table_id = aws_route_table.VPC_B_pub_rt.id
}

# Assoc VPC B public RT to public SN AZ2
resource "aws_route_table_association" "VPC_B_pub_rt_to_b" {
  subnet_id      = aws_subnet.VPC_B_pub_sn_b.id
  route_table_id = aws_route_table.VPC_B_pub_rt.id
}

# Assoc VPC B private RT to private SN AZ1
resource "aws_route_table_association" "VPC_B_pri_rt_to_a" {
  subnet_id      = aws_subnet.VPC_B_pri_sn_a.id
  route_table_id = aws_route_table.VPC_B_pri_rt.id
}

# Assoc VPC B private RT to private SN AZ2
resource "aws_route_table_association" "VPC_B_pri_rt_to_b" {
  subnet_id      = aws_subnet.VPC_B_pri_sn_b.id
  route_table_id = aws_route_table.VPC_B_pri_rt.id
}


# Internet GW
resource "aws_internet_gateway" "VPC_B_igw" {
  vpc_id = aws_vpc.VPC_B.id

  tags = {
    Name = "VPC B IGW"
  }
}

# public IP for NAT
resource "aws_eip" "VPC_B_eip_natgw" {
  vpc = true
  tags = {
    Name = "VPC B NAT GW IP"
  }
}

# NAT gateway connected to public subnet AZ1
resource "aws_nat_gateway" "VPC_B_natgw" {
  allocation_id = aws_eip.VPC_B_eip_natgw.id
  subnet_id     = aws_subnet.VPC_B_pub_sn_a.id

  tags = {
    Name = "VPC B NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.VPC_B_igw]
}

# Security group for KMS
resource "aws_security_group" "VPC_B_kms_sg" {
  name        = "sg_kms"
  description = "Allow all"
  vpc_id      = aws_vpc.VPC_B.id

  tags = {
    Name = "Security Group for KMS"
  }
}

resource "aws_vpc_security_group_ingress_rule" "VPC_B_ig_traffic_ipv4" {
  security_group_id = aws_security_group.VPC_B_kms_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "VPC_B_eg_traffic_ipv4" {
  security_group_id = aws_security_group.VPC_B_kms_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



#Endpoint
resource "aws_vpc_endpoint" "VPC_B_kms2" {
  vpc_id       = aws_vpc.VPC_B.id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.us-east-1.kms"
  private_dns_enabled = true
  subnet_ids        = [aws_subnet.VPC_B_pri_sn_a.id, aws_subnet.VPC_B_pri_sn_b.id]
  security_group_ids = [ aws_security_group.VPC_B_kms_sg.id ]
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  tags = {
    Name = "VPC B KMS Endpoint"
  }
}

resource "aws_vpc_endpoint" "VPC_B_s3" {
  vpc_id       = aws_vpc.VPC_B.id
  vpc_endpoint_type = "Gateway"
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids        = [aws_route_table.VPC_B_pri_rt.id, aws_route_table.VPC_B_pub_rt.id]
  tags = {
    Name = "VPC B S3 Endpoint"
  }
}


