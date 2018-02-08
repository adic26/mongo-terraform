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
  default = "~/.ssh/markbm.pem"
}

variable "tag_name" {
  description = "The AWS tag name."
  default = "markbm terraform test"
}

variable "region" {
  description = "The AWS region"
  default = "eu-west-1"
}

variable "replset" {
  description = "The replica set name"
  default = "appdb"
}

variable "servers" {
  description = "The number of servers"
  default = "1"
}

module "ec2" {
  source = "./shared"
  region = "${var.region}"
}

module "vpc" {
  source   = "./vpc"
  region   = "${var.region}"
  owner    = "${var.owner}"
  tag_name = "${var.tag_name}"
}

module "ec2_instances" {
  source         = "./ec2_spot"
  ami_id         = "${module.ec2.ami_id}"
  ami_username   = "${module.ec2.ami_username}"
  region         = "${var.region}"
  owner          = "${var.owner}"
  key_name       = "${var.key_name}"
  key_path       = "${var.key_path}"
  security_group = "${module.vpc.opsmgr_sg}"
  subnet_ids     = "${module.vpc.subnet_ids}"
  zones          = "3"
  expire_on      = "${var.expire_on}"
  tag_name       = "${var.tag_name}"
  instance_type  = "t2.large"
  volume_size    = "20"
  volume_type    = "gp2"
  volume_iops    = "1000"
  servers        = "${var.servers}"
  spot_price     = "0.05"
}

module "mongodb" {
  source         = "./mongodb"
  region         = "${var.region}"
  key_name       = "${var.key_name}"
  key_path       = "${var.key_path}"
  ami_username   = "${module.ec2.ami_username}"
  replset        = "${var.replset}"
  servers        = "${var.servers}"
  public_ips     = "${module.ec2_instances.public_ips}"
  private_ips    = "${module.ec2_instances.private_ips}"
  volume_ids     = "${module.ec2_instances.volume_ids}"
}

output "public_ips" {
  value = "${module.ec2_instances.public_ips}"
}