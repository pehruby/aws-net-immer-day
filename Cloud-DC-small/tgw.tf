
# Transit gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description = "TGW for us-east-1"
  multicast_support = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "TGW"
  }
}


# TGW attachment to VPC A
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_A_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_A_tgw_sn_a.id, aws_subnet.VPC_A_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  vpc_id             = aws_vpc.VPC_A.id
}



/*
# TGW attachment to VPC B
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_B_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_B_tgw_sn_a.id, aws_subnet.VPC_B_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  vpc_id             = aws_vpc.VPC_B.id
}

# TGW attachment to VPC C
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_C_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_C_tgw_sn_a.id, aws_subnet.VPC_C_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  vpc_id             = aws_vpc.VPC_C.id
}

*/

resource "aws_ec2_transit_gateway_route_table" "shared_svc" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "Shared Serices TGW Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table" "my_default" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "My default TGW Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table" "vpn" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "VPN TGW Route Table"
  }
}

# Associate VPC A to shared services routing table
resource "aws_ec2_transit_gateway_route_table_association" "VPC_A_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_svc.id
}

# Associate VPN attachment to vpn routing table
resource "aws_ec2_transit_gateway_route_table_association" "VPN_to_vpn" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.VPN_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn.id
}




/*
# VPC B propagation from shared services RT
resource "aws_ec2_transit_gateway_route_table_propagation" "VPC_B_from_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_B_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_svc.id
}

# VPC C propagation from shared services RT
resource "aws_ec2_transit_gateway_route_table_propagation" "VPC_C_from_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_C_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_svc.id
}

# Associate VPC B to "my default" routing table
resource "aws_ec2_transit_gateway_route_table_association" "VPC_B_to_my_default" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_B_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my_default.id
}

# Associate VPC C to "my default" routing table
resource "aws_ec2_transit_gateway_route_table_association" "VPC_C_to_my_default" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_C_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my_default.id
}

*/


# VPC A propagation from vpn RT
resource "aws_ec2_transit_gateway_route_table_propagation" "VPC_A_from_vpn" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn.id
}

# VPN propagation from shared services RT
resource "aws_ec2_transit_gateway_route_table_propagation" "VPN_from_shared" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.VPN_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_svc.id
}

# Static route to remote side ("On Prem") on VPN table
resource "aws_ec2_transit_gateway_route" "static_OP_vpn_rt" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.VPN_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn.id
}

# Static route to remote side ("On Prem") on Shared Services RT
resource "aws_ec2_transit_gateway_route" "static_OP_shared_rt" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.VPN_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_svc.id
}