variable "expire_on" {
  description = "When the provisioned instances should expire."
}

variable "owner" {
  description = "Resource owner name for tagging"
}

variable "tag_name" {
  description = "The AWS tag name."
}

variable "region" {
  description = "The AWS region."
}

variable "security_group" {
  description = "The AWS Security Group ID."
}

variable "subnet_ids" {
  type = "list"
  description = "The AWS Security Group IDs."
}

variable "zones" {
  description = "Number of availability zones to use"
}

variable "volume_size" {
  description = "EBS disk size."
}

variable "volume_type" {
  description = "EBS disk volume type (standard, io1, gp2)."
}

variable "volume_iops" {
  description = "The amount of provisioned IOPS. This must be set with a volume_type of 'io1'."
}

variable "ami_id" {
  description = "the id of the AMI to use for the EC2 instances"
}

variable "ami_username" {
  description = "the username to use to ssh to the EC2 instance"
}

variable "servers" {
  description = "The number of servers to instantiate."
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "key_path" {
  description = "Path to the private key specified by key_name."
}

variable "instance_type" {
  description = "AWS Instance type."
}