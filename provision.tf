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
  default = "mark's terraform test"
}

variable "servers" {
  description = "The number of mongod servers to launch."
  default = 1
}

variable "region" {
  description = "The AWS region"
  default = "eu-west-1"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS Instance type."
}

variable "volume_size" {
  description = "EBS disk size."
  default     = 2
}

variable "volume_type" {
  description = "EBS disk volume type (standard, io1, gp2)."
  default     = "standard"
}

variable "volume_iops" {
  description = "The amount of provisioned IOPS. This must be set with a volume_type of 'io1'."
  default     = 101
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
  source         = "./mongod"
  ami_id         = "${module.ec2.ami_id}"
  ami_username   = "${module.ec2.ami_username}"
  region         = "${var.region}"
  owner          = "${var.owner}"
  key_name       = "${var.key_name}"
  key_path       = "${var.key_path}"
  security_group = "${module.vpc.security_group}"
  subnet_id      = "${module.vpc.subnet_id}"
  expire_on      = "${var.expire_on}"
  tag_name       = "${var.tag_name}"
  instance_type  = "${var.instance_type}"
  volume_size    = "${var.volume_size}"
  volume_type    = "${var.volume_type}"
  volume_iops    = "${var.volume_iops}"
  servers        = "${var.servers}"
}

output "ip" {
  value = "${module.mongod.ip}"
}