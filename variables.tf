variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "key_name" {
  type = string
}

variable "env_profiles" {
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    db_class      = string
    multi_az      = bool
  }))
  default = {
    test = {
      instance_type = "t3.micro"
      min_size      = 1
      max_size      = 3
      desired_size  = 1
      db_class      = "db.t3.micro"
      multi_az      = false
    }
    dev = {
      instance_type = "t3.small"
      min_size      = 2
      max_size      = 3
      desired_size  = 2
      db_class      = "db.t3.micro"
      multi_az      = false
    }
    prod = {
      instance_type = "t3.medium"
      min_size      = 2
      max_size      = 6
      desired_size  = 2
      db_class      = "db.t3.medium"
      multi_az      = true
    }
  }
}