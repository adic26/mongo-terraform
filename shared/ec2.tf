provider "aws" {
  region = "${var.region}"
}

variable "region" {
  description = "The AWS region."
}

variable "platform" {
  description = "linux platform for user name resolution (amazon,ubuntu,centos6,centos7,rhel6,rhel7)"
  default     = "amazon"
}

# get the most recent amazon linux ami
data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${lookup(var.ami_filters, var.platform)}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${lookup(var.ami_owners, var.platform)}"]
}

variable "user" {
  type = "map"

  default = {
    ubuntu  = "ubuntu"
    rhel6   = "ec2-user"
    centos6 = "centos"
    centos7 = "centos"
    rhel7   = "ec2-user"
    amazon  = "ec2-user"
  }
}

variable "ami_filters" {
  type = "map"

  default = {
    rhel7   = "RHEL-7.4_HVM*"
    amazon2 = "amzn2-ami-hvm-*-gp2"
    amazon  = "amzn-ami-hvm-*-gp2"
  }
}

variable "ami_owners" {
  type = "map"
  
  default = {
    rhel7   = "309956199498"
    rhel6   = "309956199498"
    amazon2 = "137112412989"
    amazon  = "137112412989"
  }
}

output "ami_id" {
  value = "${data.aws_ami.linux.id}"
}

output "ami_username" {
  value = "${lookup(var.user, var.platform)}"
}