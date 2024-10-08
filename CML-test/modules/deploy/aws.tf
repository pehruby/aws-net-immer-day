terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.56.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.3"
    }

  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  #secret_key = var.aws_secret_key
  #access_key = var.aws_access_key
  region = var.cfg.aws.region
}

module "aws" {
  source  = "./aws"
  count   = var.cfg.target == "aws" ? 1 : 0
  options = local.options
}
