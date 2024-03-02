
# Transit gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description = "TGW for us-east-1"
  multicast_support = "enable"

  tags = {
    Name = "TGW"
  }
}

# TGW attachment to VPC A
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_A_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_A_tgw_sn_a.id, aws_subnet.VPC_A_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.VPC_A.id
}

# TGW attachment to VPC B
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_B_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_B_tgw_sn_a.id, aws_subnet.VPC_B_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.VPC_B.id
}

# TGW attachment to VPC B
resource "aws_ec2_transit_gateway_vpc_attachment" "VPC_C_tgw_attach" {
  subnet_ids         = [aws_subnet.VPC_C_tgw_sn_a.id, aws_subnet.VPC_C_tgw_sn_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.VPC_C.id
}
