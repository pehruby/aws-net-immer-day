
### VPN GW server

resource "aws_security_group" "VPC_OP_sg_gw_server" {
  vpc_id = aws_vpc.VPC_OP.id
  name = "On-Premises Customer Gateway Security Group"
  description = "Security group for Customer Gateway Server"

  
  tags = {
    Name = "On-Premises Customer Gateway Security Group"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_gw_ingress_1" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_gw_ingress_2" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "172.16.0.0/16"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_gw_ingress_3" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 500
  ip_protocol       = "udp"
  to_port           = 500
}

resource "aws_vpc_security_group_ingress_rule" "sg_gw_ingress_4" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = 4500
  ip_protocol       = "udp"
  to_port           = 4500
}

# Probably not needed ?
resource "aws_vpc_security_group_ingress_rule" "sg_gw_ingress_5" {
  security_group_id = aws_security_group.VPC_OP_sg_gw_server.id
  cidr_ipv4         = "52.91.174.4/32"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}



resource "aws_vpc_security_group_egress_rule" "sg_gw_egress_1" {
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
  # source/destination checking must be disabled on ENI !!!
  source_dest_check = false
  vpc_security_group_ids = [ aws_security_group.VPC_OP_sg_gw_server.id ]
  subnet_id   = aws_subnet.VPC_OP_pub_sn_a.id
  associate_public_ip_address = true


  tags = {
    Name = "On-Premises Customer Gateway"
  }

  # depends_on = [ aws_instance.VPC_OP_dns_server ]

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


### App server

resource "aws_security_group" "VPC_OP_sg_app_server" {
  vpc_id = aws_vpc.VPC_OP.id
  name = "On-Premises App Server Security Group"
  description = "Security group for App Server"

  
  tags = {
    Name = "On-Premises App Server Security Group"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_app_ingress_1" {
  security_group_id = aws_security_group.VPC_OP_sg_app_server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "sg_app_ingress_2" {
  security_group_id = aws_security_group.VPC_OP_sg_app_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_app_ingress_3" {
  security_group_id = aws_security_group.VPC_OP_sg_app_server.id
  cidr_ipv4         = "172.16.0.0/16"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

# Probably not needed ?
resource "aws_vpc_security_group_ingress_rule" "sg_app_ingress_4" {
  security_group_id = aws_security_group.VPC_OP_sg_app_server.id
  cidr_ipv4         = "52.91.174.4/32"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "sg_app_egress_1" {
  security_group_id = aws_security_group.VPC_OP_sg_app_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 --region us-east-1 
resource "aws_instance" "VPC_OP_app_server" {
  ami           = "ami-0440d3b780d96b29d"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.op_server_ias_profile.name
  private_ip = "172.16.1.100"
  vpc_security_group_ids = [ aws_security_group.VPC_OP_sg_app_server.id ]
  subnet_id   = aws_subnet.VPC_OP_pri_sn_a.id
  associate_public_ip_address = true


  tags = {
    Name = "On-Premises App Server"
  }

  user_data = <<EOF
#!/bin/bash
# set up web server
dnf install -y httpd
echo "Hello, world." > /var/www/html/index.html
systemctl enable httpd.service
systemctl start httpd.service
EOF
}


### DNS server

resource "aws_security_group" "VPC_OP_sg_dns_server" {
  vpc_id = aws_vpc.VPC_OP.id
  name = "On-Premises DNS Security Group"
  description = "Security group for DNS"

  
  tags = {
    Name = "On-Premises DNS Security Group"
  }

}

resource "aws_vpc_security_group_ingress_rule" "sg_dns_ingress_1" {
  security_group_id = aws_security_group.VPC_OP_sg_dns_server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  ip_protocol       = "udp"
  to_port           = 53
}

resource "aws_vpc_security_group_ingress_rule" "sg_dns_ingress_2" {
  security_group_id = aws_security_group.VPC_OP_sg_dns_server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  ip_protocol       = "tcp"
  to_port           = 53
}

resource "aws_vpc_security_group_ingress_rule" "sg_dns_ingress_3" {
  security_group_id = aws_security_group.VPC_OP_sg_dns_server.id
  cidr_ipv4         = "10.0.0.0/8"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "sg_dns_ingress_4" {
  security_group_id = aws_security_group.VPC_OP_sg_dns_server.id
  cidr_ipv4         = "172.16.0.0/16"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

# Probably not needed ?
resource "aws_vpc_security_group_ingress_rule" "sg_dns_ingress_5" {
  security_group_id = aws_security_group.VPC_OP_sg_dns_server.id
  cidr_ipv4         = "52.91.174.4/32"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "sg_dns_egress_1" {
  security_group_id = aws_security_group.VPC_OP_sg_dns_server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64 --region us-east-1 
resource "aws_instance" "VPC_OP_dns_server" {
  ami           = "ami-0440d3b780d96b29d"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.op_server_ias_profile.name
  private_ip = "172.16.1.200"
  vpc_security_group_ids = [ aws_security_group.VPC_OP_sg_dns_server.id ]
  subnet_id   = aws_subnet.VPC_OP_pri_sn_a.id
  associate_public_ip_address = true


  tags = {
    Name = "On-Premises DNS Server"
  }
// "${file("install.sh")}"
  user_data = <<EOQ
#!/bin/bash
# set up DNS server
dnf install -y bind

# replace named.conf
cat > /etc/named.conf<< EOW
options {
  directory       "/var/named";
  dump-file       "/var/named/data/cache_dump.db";
  statistics-file "/var/named/data/named_stats.txt";
  memstatistics-file "/var/named/data/named_mem_stats.txt";
  recursing-file  "/var/named/data/named.recursing";
  secroots-file   "/var/named/data/named.secroots";

  recursion yes;

  allow-query { any; };

  dnssec-enable no;
  dnssec-validation no;

  bindkeys-file "/etc/named.root.key";

  managed-keys-directory "/var/named/dynamic";

  pid-file "/run/named/named.pid";
  session-keyfile "/run/named/session.key";

  forwarders {
          169.254.169.253;
  };
  forward first;
};

logging {
  channel default_debug {
      file "data/named.run";
      severity dynamic;
  };
};


zone "." IN {
        type hint;
        file "named.ca";
};

zone "example.corp" IN {
        type master;
        file "/etc/named/example.corp";
        allow-update { none; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOW

# build zone file with my IP address and AppServer IP.
ORIGIN='$ORIGIN'
APPIP='172.16.1.100'
MYIP='172.16.1.200'

cat > /etc/named/example.corp<< EOE
$ORIGIN example.corp.
@                      3600 SOA   ns.example.corp. (
                                  zone-admin.example.com.     ; address of responsible party
                                  2020050701                 ; serial number
                                  3600                       ; refresh period                                    
                                  600                        ; retry period
                                  604800                     ; expire time
                                  1800                     ) ; minimum ttl
                      86400 NS    ns1.example.corp.
myapp                    60 IN A  $APPIP
ns1                      60 IN A  $MYIP
EOE

# activate DNS server
systemctl enable named.service
systemctl start named.service

# set up as local DNS resolver
cat > /etc/resolv.conf<< EOF
search example.corp
nameserver $MYIP
EOF

EOQ
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

