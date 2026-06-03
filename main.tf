terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}


locals {
  profile = var.env_profiles[var.environment]
}

module "wordpress_stack" {
  source = "./modules"

  vpc_cidr        = var.vpc_cidr
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.11.0/24", "10.1.12.0/24"]
  key_name        = var.key_name
  environment     = var.environment
  db_password     = var.db_password


  instance_class   = local.profile.db_class
  multi_az         = local.profile.multi_az
  instance_type    = local.profile.instance_type
  min_size         = local.profile.min_size
  max_size         = local.profile.max_size
  desired_capacity = local.profile.desired_size
}

resource "aws_key_pair" "deployer" {
  key_name   = "my-ssh-key"
  public_key = file("/home/cloudshell-user/.ssh/id_rsa.pub")
}