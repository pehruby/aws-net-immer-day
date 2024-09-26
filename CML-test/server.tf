resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "random_id" "id" {
  byte_length = 4
}


resource "aws_security_group" "sg_tf" {
  name        = "tf-sg-cml-${random_id.id.hex}"
  description = "CML required ports inbound/outbound"
  tags = {
    Name = "tf-sg-cml-${random_id.id.hex}"
  }
  vpc_id = aws_vpc.VPC_A.id
  egress = [
    {
      "description" : "any",
      "from_port" : 0,
      "to_port" : 0
      "protocol" : "-1",
      "cidr_blocks" : [
        "0.0.0.0/0"
      ],
      "ipv6_cidr_blocks" : [],
      "prefix_list_ids" : [],
      "security_groups" : [],
      "self" : false,
    }
  ]
  ingress = local.cfg.common.enable_patty ? concat(local.cml_ingress, local.cml_patty_range) : local.cml_ingress
}

resource "aws_network_interface" "pub_int_cml" {
  subnet_id       = aws_subnet.VPC_A_pub_sn_a.id
  security_groups = [aws_security_group.sg_tf.id]
  tags            = { Name = "CML-controller-pub-int-${random_id.id.hex}" }
}

resource "aws_eip" "server_eip" {
  network_interface = aws_network_interface.pub_int_cml.id
  tags              = { "Name" = "CML-controller-eip-${random_id.id.hex}", "device" = "server" }
}

resource "aws_instance" "cml_controller" {
  instance_type = local.cfg.aws.flavor
  #ami                  = data.aws_ami.ubuntu.id
  ami = "ami-0e731c8a588258d0d"
  #iam_instance_profile = local.cfg.aws.profile
  iam_instance_profile = aws_iam_instance_profile.server_ias_profile.name
  #key_name             = local.cfg.common.key_name
  key_name      = aws_key_pair.ssh_key.key_name
  tags          = { Name = "CML-controller-${random_id.id.hex}" }
  ebs_optimized = "true"
  depends_on    = [aws_route_table_association.VPC_A_pub_rt_to_a]
  root_block_device {
    volume_size = local.cfg.common.disk_size
    volume_type = "gp3"
    encrypted   = local.cfg.aws.enable_ebs_encryption
  }
  network_interface {
    network_interface_id = aws_network_interface.pub_int_cml.id
    device_index         = 0
  }
  #user_data = data.cloudinit_config.cml_controller.rendered
}



data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Owner ID of Canonical
}

/*
data "cloudinit_config" "cml_compute" {
  gzip          = true
  base64_encode = true # always true if gzip is true
  count         = local.num_computes

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = local.cloud_config_compute[count.index]
  }
}
*/
