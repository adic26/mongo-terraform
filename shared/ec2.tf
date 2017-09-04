provider "aws" {
  region = "${var.region}"
}

variable "ami_owner" {
  description = "AMI owner filter"
  default     = "137112412989" # amazon
}

variable "ami_name_filter" {
  description = "AMI name filter"
  default     = "amzn-ami-hvm-*-gp2"
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
    values = ["${var.ami_name_filter}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.ami_owner}"]
}

variable "user" {
  default = {
    ubuntu  = "ubuntu"
    rhel6   = "ec2-user"
    centos6 = "centos"
    centos7 = "centos"
    rhel7   = "ec2-user"
    amazon  = "ec2-user"
  }
}

output "ami_id" {
  value = "${data.aws_ami.linux.id}"
}

output "ami_username" {
  value = "${lookup(var.user, var.platform)}"
}