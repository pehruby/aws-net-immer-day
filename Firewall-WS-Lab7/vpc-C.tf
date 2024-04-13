# Create a VPC
resource "aws_vpc" "VPC_C" {
  cidr_block = "172.31.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "AnfwDemo-IngressVPC"
  }
}

# Internet GW
resource "aws_internet_gateway" "VPC_C_igw" {
  vpc_id = aws_vpc.VPC_C.id

  tags = {
    Name = "AnfwDemo-IngressVPC-IGW"
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

# private subnet
resource "aws_subnet" "VPC_C_pri_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "172.31.121.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "AnfwDemo-IngressVPC-PrivateSubnetA"
  }
}


# public subnet
resource "aws_subnet" "VPC_C_pub_a" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "172.31.111.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "AnfwDemo-IngressVPC-PublicSubnetA"
  }
}





# private RT
resource "aws_route_table" "VPC_C_pri_a" {
  vpc_id = aws_vpc.VPC_C.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_C_natgw_a.id
  }

  tags = {
    Name = "AnfwDemo-IngressVPC-PrivateRtbA"
  }
}

# Assoc pri RT to pri subnet
resource "aws_route_table_association" "VPC_C_pri_rt_to_a" {
  subnet_id      = aws_subnet.VPC_C_pri_a.id
  route_table_id = aws_route_table.VPC_C_pri_a.id
}

# RT for public subnet C
resource "aws_route_table" "VPC_C_pub_a" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_C_igw.id
  }

  tags = {
    Name = "AnfwDemo-IngressVPC-PublicRtbA"
  }
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

# private subnet
resource "aws_subnet" "VPC_C_pri_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "172.31.122.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "AnfwDemo-IngressVPC-PrivateSubnetB"
  }
}


# public subnet
resource "aws_subnet" "VPC_C_pub_b" {
  vpc_id     = aws_vpc.VPC_C.id
  cidr_block = "172.31.112.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "AnfwDemo-IngressVPC-PublicSubnetB"
  }
}




# RT for private subnet
resource "aws_route_table" "VPC_C_pri_b" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.VPC_C_natgw_b.id
  }

  tags = {
    Name = "AnfwDemo-IngressVPC-PrivateRtbB"
  }
}

# Assoc pri RT to pri subnet B
resource "aws_route_table_association" "VPC_C_pri_rt_to_b" {
  subnet_id      = aws_subnet.VPC_C_pri_b.id
  route_table_id = aws_route_table.VPC_C_pri_b.id
}

# RT for public subnet 
resource "aws_route_table" "VPC_C_pub_b" {
  vpc_id = aws_vpc.VPC_C.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_C_igw.id
  }

  tags = {
    Name = "AnfwDemo-IngressVPC-PublicRtbB"
  }
}

# Assoc VPC C public RT to public SN
resource "aws_route_table_association" "VPC_C_pub_rt_to_b" {
  subnet_id      = aws_subnet.VPC_C_pub_b.id
  route_table_id = aws_route_table.VPC_C_pub_b.id
}



resource "aws_security_group" "VPC_C_sg_alb" {
  vpc_id = aws_vpc.VPC_C.id
  name = "AnfwDemo-IngressVPC-ALBSg"
  description = "Access to ALB: allow HTTP and HTTPS VPC CIDR."

  
  tags = {
    Name = "AnfwDemo-IngressVPC-ALBSg"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_alb_ingress_1" {
  security_group_id = aws_security_group.VPC_C_sg_alb.id
  cidr_ipv4         = "172.31.0.0/16"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "sg_alb_ingress_2" {
  security_group_id = aws_security_group.VPC_C_sg_alb.id
  cidr_ipv4         = "172.31.0.0/16"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_egress_rule" "sg_alb_C_egress_1" {
  security_group_id = aws_security_group.VPC_C_sg_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



resource "aws_security_group" "VPC_C_sg_web" {
  vpc_id = aws_vpc.VPC_C.id
  name = "AnfwDemo-IngressVPC-WebInstanceSg"
  description = "Allow all traffic from ALB security group and ICMP from VPC CIDR."

  
  tags = {
    Name = "AnfwDemo-IngressVPC-WebInstanceSg"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_web_ingress_1" {
  security_group_id = aws_security_group.VPC_C_sg_web.id
  cidr_ipv4         = "172.31.0.0/16"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_web_ingress_2" {
  security_group_id = aws_security_group.VPC_C_sg_web.id
  referenced_security_group_id = aws_security_group.VPC_C_sg_alb.id
  from_port         = -1
  ip_protocol       = "-1"
  to_port           = -1
}


resource "aws_vpc_security_group_egress_rule" "sg_web_C_egress_1" {
  security_group_id = aws_security_group.VPC_C_sg_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# Security group for KMS
resource "aws_security_group" "kms_sg" {
  name        = "sg_kms"
  description = "Allow all"
  vpc_id      = aws_vpc.VPC_C.id

  tags = {
    Name = "Security Group for KMS"
  }
}
#Endpoint
resource "aws_vpc_endpoint" "kms2" {
  vpc_id       = aws_vpc.VPC_C.id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.us-east-1.kms"
  private_dns_enabled = true
  subnet_ids        = [aws_subnet.VPC_C_pri_a.id, aws_subnet.VPC_C_pri_b.id]
  security_group_ids = [ aws_security_group.kms_sg.id ]
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  tags = {
    Name = "VPC A KMS Endpoint"
  }
}

resource "aws_lb" "external" {
  name               = "AnfwDemo-IngressVPC-ExternalAlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.VPC_C_sg_alb.id]
  subnets            = [aws_subnet.VPC_C_pub_a.id, aws_subnet.VPC_C_pub_b.id]
  

  tags = {
    Name = "AnfwDemo-IngressVPC-ExternalAlb"
  }
}

resource "aws_lb_target_group" "tg1" {
  name     = "AnfwDemo-IngressVPC-Tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.VPC_C.id
  target_type = "instance"
  health_check {
    port = 80
    protocol = "HTTP"
    timeout = 20
  }


  tags = {
    Name = "AnfwDemo-IngressVPC-Tg1"
  }
}

resource "aws_lb_target_group_attachment" "server1" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.web_A.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "server2" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.web_B.id
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }
}