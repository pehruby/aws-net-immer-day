# VPC A with VPC B
resource "aws_vpc_peering_connection" "VPC_A-B_peering_connection" {
  peer_vpc_id  = aws_vpc.VPC_B.id
  vpc_id = aws_vpc.VPC_A.id
  auto_accept   = true

  tags = {
    Name = "VPC A <> VPC B"
  }
}

# VPC A with VPC B
resource "aws_vpc_peering_connection" "VPC_A-C_peering_connection" {
  peer_vpc_id  = aws_vpc.VPC_C.id
  vpc_id = aws_vpc.VPC_A.id
  auto_accept   = true

  tags = {
    Name = "VPC A <> VPC C"
  }
}

