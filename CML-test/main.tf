/*
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.56.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = local.cfg.aws.region
}
*/


module "secrets" {
  source = "./modules/secrets"
  cfg    = local.raw_cfg
}

module "deploy" {
  source = "./modules/deploy"
  cfg    = local.cfg
  extras = local.extras
}
