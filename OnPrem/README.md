When "On-Premises Customer Gateway" EC2 instance is started, note the public IP address.
The address must be used in vpn configuration of the opposite side (Cloud-DC-small/vpn.tf)
Also the address must by updated in ingress rule of Customer GW security group, so that the server is pingable

When VPN gateway is started, On-Prem Customer Gateway must by manualy configured and IPsec started.
Details are here: https://catalog.workshops.aws/networking/en-US/foundational/on-premises/create-vpn
