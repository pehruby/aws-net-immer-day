
/*
resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.VPC_A.id
}
*/

resource "aws_customer_gateway" "on_oprem" {
  bgp_asn    = 65000
  # IP address must by changed, dynamic public IP of remote site must be used
  ip_address = "52.91.174.4"
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "main" {
  # vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.on_oprem.id
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "On-Premises S2S VPN"
  }
}

# EC2 Transit Gateway VPN Attachments are implicitly created by VPN Connections
# we have to create data object so that the attachment can be used (to attach a route table) 
data "aws_ec2_transit_gateway_vpn_attachment" "VPN_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpn_connection_id  = aws_vpn_connection.main.id
}
