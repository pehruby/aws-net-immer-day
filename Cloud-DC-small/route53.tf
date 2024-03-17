# VPC uses standard Route 53 DNS for VPC/Internet resolution, 
# resulution requests related to example.corp are forwarded to "On-prem" DNS 172.16.1.200


resource "aws_route53_resolver_endpoint" "nd_outbound" {
  name      = "NetworkingDayOutbound"
  direction = "OUTBOUND"
 

  security_group_ids = [
    aws_security_group.VPC_A_sg_server1.id,
  ]

  ip_address {
    subnet_id = aws_subnet.VPC_A_pri_sn_a.id
  }

  ip_address {
    subnet_id = aws_subnet.VPC_A_pri_sn_b.id
  }




  tags = {
    Name = "NetworkingDayOutbound"
  }
}

resource "aws_route53_resolver_rule" "nd_forward" {
  domain_name          = "example.corp"
  name                 = "NetworkingDayRule"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.nd_outbound.id

  target_ip {
    ip = "172.16.1.200"
    port = "53"
  }

  tags = {
    Name = "NetworkingDayRule"
  }
}

resource "aws_route53_resolver_rule_association" "nd_forward_to_VPCA" {
  resolver_rule_id = aws_route53_resolver_rule.nd_forward.id
  vpc_id           = aws_vpc.VPC_A.id
}