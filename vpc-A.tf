# Create a VPC
resource "aws_vpc" "VPC_A" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "VPC A"
  }
}

resource "aws_subnet" "VPC_A_pub_sn_a" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC A Public Subnet AZ1"
  }
}

resource "aws_subnet" "VPC_A_pri_sn_a" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC A Private Subnet AZ1"
  }
}

resource "aws_subnet" "VPC_A_pub_sn_b" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "VPC A Public Subnet AZ2"
  }
}

resource "aws_subnet" "VPC_A_pri_sn_b" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "VPC A Private Subnet AZ2"
  }
}

resource "aws_subnet" "VPC_A_tgw_sn_a" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.5.0/28"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC A TGW Subnet AZ1"
  }
}

resource "aws_subnet" "VPC_A_tgw_sn_b" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.5.16/28"
  availability_zone = "us-east-1b"

  tags = {
    Name = "VPC A TGW Subnet AZ2"
  }
}

# if no entries are specified, it is only default entry which denies all created
resource "aws_network_acl" "VPC_A_wls_acl" {
  vpc_id = aws_vpc.VPC_A.id

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
    Name = "VPC A Workload Subnets NACL"
  }
}

# Associate ACL with all 4 subnets (private and public)
resource "aws_network_acl_association" "VPC_A_assoc_acl_puba" {
  network_acl_id = aws_network_acl.VPC_A_wls_acl.id
  subnet_id      = aws_subnet.VPC_A_pub_sn_a.id
}

resource "aws_network_acl_association" "VPC_A_assoc_acl_pria" {
  network_acl_id = aws_network_acl.VPC_A_wls_acl.id
  subnet_id      = aws_subnet.VPC_A_pri_sn_a.id
}

resource "aws_network_acl_association" "VPC_A_assoc_acl_pubb" {
  network_acl_id = aws_network_acl.VPC_A_wls_acl.id
  subnet_id      = aws_subnet.VPC_A_pub_sn_b.id
}

resource "aws_network_acl_association" "VPC_A_assoc_acl_prib" {
  network_acl_id = aws_network_acl.VPC_A_wls_acl.id
  subnet_id      = aws_subnet.VPC_A_pri_sn_b.id
}


# RT for public subnets
# by default only one enry which routes VPC range to local
resource "aws_route_table" "VPC_A_pub_rt" {
  vpc_id = aws_vpc.VPC_A.id

  # IGW defined bellow in the file
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_A_igw.id
  }

  tags = {
    Name = "VPC A Public Route Table"
  }
}

# RT for private subnets
resource "aws_route_table" "VPC_A_pri_rt" {
  vpc_id = aws_vpc.VPC_A.id

  # default route to NAT GW in public subnet
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_A_natgw.id
  }


  # route to TGW
  route {
    cidr_block = "10.1.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }

  # route to TGW
  route {
    cidr_block = "10.2.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }


  tags = {
    Name = "VPC A Private Route Table"
  }
}

# Assoc VPC A public RT to public SN AZ1
resource "aws_route_table_association" "VPC_A_pub_rt_to_a" {
  subnet_id      = aws_subnet.VPC_A_pub_sn_a.id
  route_table_id = aws_route_table.VPC_A_pub_rt.id
}

# Assoc VPC A public RT to public SN AZ2
resource "aws_route_table_association" "VPC_A_pub_rt_to_b" {
  subnet_id      = aws_subnet.VPC_A_pub_sn_b.id
  route_table_id = aws_route_table.VPC_A_pub_rt.id
}

# Assoc VPC A private RT to private SN AZ1
resource "aws_route_table_association" "VPC_A_pri_rt_to_a" {
  subnet_id      = aws_subnet.VPC_A_pri_sn_a.id
  route_table_id = aws_route_table.VPC_A_pri_rt.id
}

# Assoc VPC A private RT to private SN AZ2
resource "aws_route_table_association" "VPC_A_pri_rt_to_b" {
  subnet_id      = aws_subnet.VPC_A_pri_sn_b.id
  route_table_id = aws_route_table.VPC_A_pri_rt.id
}


# Internet GW
resource "aws_internet_gateway" "VPC_A_igw" {
  vpc_id = aws_vpc.VPC_A.id

  tags = {
    Name = "VPC A IGW"
  }
}

# public IP for NAT
resource "aws_eip" "eip_natgw" {
  vpc = true
  tags = {
    Name = "NAT GW IP"
  }
}

# NAT gateway connected to public subnet AZ1
resource "aws_nat_gateway" "VPC_A_natgw" {
  allocation_id = aws_eip.eip_natgw.id
  subnet_id     = aws_subnet.VPC_A_pub_sn_a.id

  tags = {
    Name = "VPC A NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.VPC_A_igw]
}

# Security group for KMS
resource "aws_security_group" "kms_sg" {
  name        = "sg_kms"
  description = "Allow all"
  vpc_id      = aws_vpc.VPC_A.id

  tags = {
    Name = "Security Group for KMS"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ig_traffic_ipv4" {
  security_group_id = aws_security_group.kms_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "eg_traffic_ipv4" {
  security_group_id = aws_security_group.kms_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



#Endpoint
resource "aws_vpc_endpoint" "kms2" {
  vpc_id       = aws_vpc.VPC_A.id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.us-east-1.kms"
  private_dns_enabled = true
  subnet_ids        = [aws_subnet.VPC_A_pri_sn_a.id, aws_subnet.VPC_A_pri_sn_b.id]
  security_group_ids = [ aws_security_group.kms_sg.id ]
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  tags = {
    Name = "VPC A KMS Endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.VPC_A.id
  vpc_endpoint_type = "Gateway"
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids        = [aws_route_table.VPC_A_pri_rt.id, aws_route_table.VPC_A_pub_rt.id]
  tags = {
    Name = "VPC A S3 Endpoint"
  }
}

# Restrict access to S3 bucket
resource "aws_vpc_endpoint_policy" "my_policy" {
    vpc_endpoint_id = aws_vpc_endpoint.s3.id
    policy = jsonencode({
        "Version": "2008-10-17",
        "Statement": [
            {
            "Sid": "ReadWriteAccess",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "*"
            }
        ]
    })
}

