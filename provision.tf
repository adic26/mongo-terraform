variable "expire_on" {
  description = "When the provisioned instances should expire"
  default = "2010-01-01"
}

variable "owner" {
  description = "Resource owner name for tagging"
  default = "mark.baker-munton"
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
  default = "markbm"
}

variable "key_path" {
  description = "Path to the private key specified by key_name."
  default = "~/.ssh/aws_personal.pem"
}

variable "tag_name" {
  description = "The AWS tag name."
}

variable "servers" {
  description = "The number of mongod servers to launch."
  default = 3
}

variable "region" {
  description = "The AWS region"
  default = "eu-west-1"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS Instance type."
}

module "vpc" {
  source = "./vpc"
  region = "${var.region}"
  owner  = "${var.owner}"
}

module "mongod" {
  source         = "./mongod"
  region         = "${var.region}"
  owner          = "${var.owner}"
  key_name       = "${var.key_name}"
  key_path       = "${var.key_path}"
  security_group = "${module.vpc.security_group}"
  subnet_id      = "${module.vpc.subnet_id}"
  expire_on      = "${var.expire_on}"
  tag_name       = "${var.tag_name}"
  instance_type  = "${var.instance_type}"
  servers        = 1
}

output "ip" {
  value = "${module.mongod.ip}"
}