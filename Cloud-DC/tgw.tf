
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

# VPC A has connectivity to VPC B and VPC C
# Associate VPC A to shared services routing table
resource "aws_ec2_transit_gateway_route_table_association" "VPC_A_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_svc.id
}

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

# VPC B and VPC C have connectivity to VPC A
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

# VPC A propagation from my_default RT
resource "aws_ec2_transit_gateway_route_table_propagation" "VPC_A_from_my_default" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC_A_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my_default.id
}
