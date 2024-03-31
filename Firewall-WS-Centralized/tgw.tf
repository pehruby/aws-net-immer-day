# Transit gateway
resource "aws_ec2_transit_gateway" "tgw_fw" {
  description = "TGW Network Firewall Demo"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments = "enable"
  amazon_side_asn = 65000
  dns_support = "enable"
  vpn_ecmp_support = "enable"

  tags = {
    Name = "AnfwDemo-TGW"
  }
}

# TGW attachment to VPC A
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_A_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_A_tgw_sn_a.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  vpc_id             = aws_vpc.VPC_A.id
  tags = {
    Name = "AnfwDemo-TGWSpokeVpcA-Attachment"
  }
}

# TGW attachment to VPC B
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_B_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_B_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  vpc_id             = aws_vpc.VPC_B.id
  tags = {
    Name = "AnfwDemo-TGWSpokeVPCB-Attachment"
  }
}

# TGW attachment to VPC C
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_C_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_C_tgw_a.id, aws_subnet.VPC_C_tgw_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  transit_gateway_default_route_table_association = "false"
  transit_gateway_default_route_table_propagation = "false"
  vpc_id             = aws_vpc.VPC_C.id
  tags = {
    Name = "AnfwDemo-TGWInspectionVPCC-Attachment"
  }
}

# TGW RT SPOKE
resource "aws_ec2_transit_gateway_route_table" "rt_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  tags = {
    Name = "AnfwDemo-TGW-SpokeRouteTable"
  }
}

# TGW RT Firewall
resource "aws_ec2_transit_gateway_route_table" "rt_fw" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  tags = {
    Name = "AnfwDemo-TGW-FirewallRouteTable"
  }
}

# Associate VPC A to TGW RT SPOKE
resource "aws_ec2_transit_gateway_route_table_association" "VPC_A_to_rt_spoke" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_spoke.id
}

# Associate VPC B to TGW RT SPOKE
resource "aws_ec2_transit_gateway_route_table_association" "VPC_B_to_rt_spoke" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_B_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_spoke.id
}

# Associate VPC C to TGW RT Firewall
resource "aws_ec2_transit_gateway_route_table_association" "VPC_C_to_rt_fw" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_C_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_fw.id
}

# 
resource "aws_ec2_transit_gateway_route" "static_spoke_insp_vpc_c" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_C_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_spoke.id
}

# 
resource "aws_ec2_transit_gateway_route" "static_fw_vpc_a" {
  destination_cidr_block         = "10.1.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_fw.id
}

resource "aws_ec2_transit_gateway_route" "static_fw_vpc_b" {
  destination_cidr_block         = "10.2.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_B_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_fw.id
}


/*
# TGW RT A
resource "aws_ec2_transit_gateway_route_table" "rt_vpca" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  tags = {
    Name = "AnfwDemo-SpokeVPCA-TGWRouteTableA"
  }
}

# Associate VPC A to TGW RT A
resource "aws_ec2_transit_gateway_route_table_association" "VPC_A_to_rt_A" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_vpca.id
}

# TGW RT B
resource "aws_ec2_transit_gateway_route_table" "rt_vpcb" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw_fw.id
  tags = {
    Name = "AnfwDemo-SpokeVPCA-TGWRouteTableB"
  }
}

# Associate VPC B to TGW RT B
resource "aws_ec2_transit_gateway_route_table_association" "VPC_B_to_rt_B" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_B_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rt_vpcb.id
}

*/
