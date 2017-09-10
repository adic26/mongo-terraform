
variable "replset_name" {}
variable "region" {}
variable "key_path" {}
variable "ami_username" {}
variable "replset_members" {type = "list"}
variable "host_ip" {}

provider "aws" {
  region = "${var.region}"
}

resource "null_resource" "bootstrap" {
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${var.host_ip}"
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
      "/tmp/scripts/bootstrap.sh ${var.replset_name} ${join(" ", var.replset_members)}"
    ]
  }
}