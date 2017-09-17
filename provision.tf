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

module "mongod" {
  source         = "./spot"
  ami_id         = "${module.ec2.ami_id}"
  ami_username   = "${module.ec2.ami_username}"
  region         = "${var.region}"
  owner          = "${var.owner}"
  key_name       = "${var.key_name}"
  key_path       = "${var.key_path}"
  security_group = "${module.vpc.opsmgr_sg}"
  subnet_ids     = "${module.vpc.subnet_ids}"
  zones          = "1"
  #vpc_id         = "${module.vpc.vpc_id}"
  expire_on      = "${var.expire_on}"
  tag_name       = "${var.tag_name}"
  instance_type  = "m4.large"
  volume_size    = "20"
  volume_type    = "gp2"
  volume_iops    = "1000"
  servers        = "1"
  replset        = "appdb"
  provision      = "mongod mms"
  spot_price     = "0.05"
}

#module "bootstrap_replset" {
#  source          = "./bootstrap-replset"
#  ami_username    = "${module.ec2.ami_username}"
#  key_path        = "${var.key_path}"
#  region          = "${var.region}"
#  replset_name    = "appdb"
#  replset_members = "${module.mongod.private_ips}"
#  host_ip         = "${element(module.mongod.public_ips, 0)}"
#}

output "public_ips" {
  value = "${module.mongod.public_ips}"
}