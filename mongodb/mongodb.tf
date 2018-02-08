provider "aws" {
  region = "${var.region}"
}

variable "region" {
  description = "The AWS region."
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "key_path" {
  description = "Path to the private key specified by key_name."
}

variable "ami_username" {
  description = "the username to use to ssh to the EC2 instance"
}

variable "replset" {
  description = "Replicaset Name."
}

variable "volume_ids" {
    description = "aws volume ids to be used as a trigger"
}

variable "public_ips" {
    type = "list"
    description = "public ips of server to login to"
}

variable "private_ips" {
    type = "list"
    description = "private ips to be used in the replica set config"
}

variable "servers" {
  description = "The number of servers in the replica set"
}

resource "template_dir" "config" {
  source_dir      = "${path.module}/config"
  destination_dir = "${path.cwd}/config"

  vars {
    replSetName	= "${var.replset}"
  }
}

resource "null_resource" "provision" {
  count = "${var.servers}"
  
#  triggers {
#    volume_attachment = "${join(",", aws_volume_attachment.data.*.id)}"
#  }

  connection {
    host = "${element(var.public_ips, count.index)}"
    user = "${var.ami_username}"
    private_key = "${file("${var.key_path}")}"
  }
  
  # copy provisioning files
  provisioner "file" {
    source = "${path.module}/scripts"
    destination = "/tmp"
  }
  
  # copy config files
  provisioner "file" {
    source = "${template_dir.config.destination_dir}"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
	  "chmod +x /tmp/scripts/provision.sh",
	  "/tmp/scripts/provision.sh mongod",
      "echo ${count.index} > /tmp/instance-number.txt"
    ]
  }

}

resource "null_resource" "bootstrap" {
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(var.public_ips, 0)}"
	user = "${var.ami_username}"
	private_key = "${file("${var.key_path}")}"
  }
  
  # bootstrap script
  provisioner "file" {
    source = "${path.module}/scripts"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
	  "chmod +x /tmp/scripts/bootstrap.sh",
      "/tmp/scripts/bootstrap.sh ${var.replset} ${join(" ", var.private_ips)}"
    ]
  }
}