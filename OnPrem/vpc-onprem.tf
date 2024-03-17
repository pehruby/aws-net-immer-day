# Create a VPC
resource "aws_vpc" "VPC_OP" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "On Premises"
  }
}

resource "aws_subnet" "VPC_OP_pub_sn_a" {
  vpc_id     = aws_vpc.VPC_OP.id
  cidr_block = "172.16.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC OnPrem Public Subnet AZ1"
  }
}

resource "aws_subnet" "VPC_OP_pri_sn_a" {
  vpc_id     = aws_vpc.VPC_OP.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPC OnPrem Private Subnet AZ1"
  }
}



# if no entries are specified, it is only default entry which denies all created
resource "aws_network_acl" "VPC_OP_wls_acl" {
  vpc_id = aws_vpc.VPC_OP.id

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
    Name = "VPC OnPrem Workload Subnets NACL"
  }
}

# Associate ACL with all 4 subnets (private and public)
resource "aws_network_acl_association" "VPC_OP_assoc_acl_puba" {
  network_acl_id = aws_network_acl.VPC_OP_wls_acl.id
  subnet_id      = aws_subnet.VPC_OP_pub_sn_a.id
}

resource "aws_network_acl_association" "VPC_OP_assoc_acl_pria" {
  network_acl_id = aws_network_acl.VPC_OP_wls_acl.id
  subnet_id      = aws_subnet.VPC_OP_pri_sn_a.id
}



# RT for public subnets
# by default only one enry which routes VPC range to local
resource "aws_route_table" "VPC_OP_pub_rt" {
  vpc_id = aws_vpc.VPC_OP.id

  # IGW defined bellow in the file
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_OP_igw.id
  }

  tags = {
    Name = "VPC OnPrem Public Route Table"
  }
}

# RT for private subnets
resource "aws_route_table" "VPC_OP_pri_rt" {
  vpc_id = aws_vpc.VPC_OP.id

  # default route to NAT GW in public subnet
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_OP_natgw.id
  }

  # route from "on-prem" to AWS via Customer Gateway server
  # source/destination checking must be disabled on ENI !!! 
  route {
    cidr_block = "10.0.0.0/8"
    network_interface_id = aws_instance.VPC_OP_pub_server.primary_network_interface_id
    #instance_id = aws_instance.VPC_OP_pub_server.id
  }



  tags = {
    Name = "VPC OnPrem Private Route Table"
  }
}

# Assoc VPC OnPrem public RT to public SN AZ1
resource "aws_route_table_association" "VPC_OP_pub_rt_to_a" {
  subnet_id      = aws_subnet.VPC_OP_pub_sn_a.id
  route_table_id = aws_route_table.VPC_OP_pub_rt.id
}


# Assoc VPC OnPrem private RT to private SN AZ1
resource "aws_route_table_association" "VPC_OP_pri_rt_to_a" {
  subnet_id      = aws_subnet.VPC_OP_pri_sn_a.id
  route_table_id = aws_route_table.VPC_OP_pri_rt.id
}



# Internet GW
resource "aws_internet_gateway" "VPC_OP_igw" {
  vpc_id = aws_vpc.VPC_OP.id

  tags = {
    Name = "VPC OnPrem IGW"
  }
}

# public IP for NAT
resource "aws_eip" "VPC_OP_eip_natgw" {
  vpc = true
  tags = {
    Name = "NAT GW IP"
  }
}

# NAT gateway connected to public subnet AZ1
resource "aws_nat_gateway" "VPC_OP_natgw" {
  allocation_id = aws_eip.VPC_OP_eip_natgw.id
  subnet_id     = aws_subnet.VPC_OP_pub_sn_a.id

  tags = {
    Name = "VPC OnPrem NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.VPC_OP_igw]
}

# Security group for KMS
resource "aws_security_group" "VPC_OP_kms_sg" {
  name        = "sg_kms"
  description = "Allow all"
  vpc_id      = aws_vpc.VPC_OP.id

  tags = {
    Name = "Security Group for KMS"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ig_traffic_ipv4" {
  security_group_id = aws_security_group.VPC_OP_kms_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "eg_traffic_ipv4" {
  security_group_id = aws_security_group.VPC_OP_kms_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



#Endpoint
resource "aws_vpc_endpoint" "kms2" {
  vpc_id       = aws_vpc.VPC_OP.id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.us-east-1.kms"
  private_dns_enabled = true
  subnet_ids        = [aws_subnet.VPC_OP_pri_sn_a.id]
  security_group_ids = [ aws_security_group.VPC_OP_kms_sg.id ]
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  tags = {
    Name = "VPC OnPrem KMS Endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.VPC_OP.id
  vpc_endpoint_type = "Gateway"
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids        = [aws_route_table.VPC_OP_pri_rt.id, aws_route_table.VPC_OP_pub_rt.id]
  tags = {
    Name = "VPC OnPrem S3 Endpoint"
  }
}

/*
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
*/

