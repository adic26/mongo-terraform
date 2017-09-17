
provider "aws" {
  region = "${var.region}"
}

resource "template_dir" "config" {
  source_dir      = "${path.module}/templates"
  destination_dir = "${path.cwd}/config"

  vars {
    replset	= "${var.replset}"
  }
}

resource "aws_instance" "cluster" {
  ami                         = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  vpc_security_group_ids      = ["${var.security_group}"]
  subnet_id                   = "${var.subnet_id}"
  key_name                    = "${var.key_name}"
  count                       = "${var.servers}"  
  associate_public_ip_address = true
  
  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = "${var.volume_size}"
    volume_type = "${var.volume_type}"
    iops        = "${var.volume_iops}"
  }
  
  connection {
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
	  "/tmp/scripts/provision.sh",
      "echo ${count.index} > /tmp/instance-number.txt"
    ]
  }
 
  tags {
    Name       = "${var.tag_name}-${count.index}"
    owner      = "${var.owner}"
    expire-on  = "${var.expire_on}"
  }
}

resource "null_resource" "bootstrap-replset" {
  # Changes to any instance of the cluster requires re-provisioning
  #triggers {
  #  cluster_instance_ids = "${join(",", aws_instance.cluster.*.id)}"
  #}

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(aws_instance.cluster.*.public_ip, 0)}"
	user = "${var.ami_username}"
	private_key = "${file("${var.key_path}")}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
	  "chmod +x /tmp/scripts/bootstrap-replset.sh",
      "/tmp/scripts/bootstrap-replset.sh ${var.replset} ${join(" ", aws_instance.cluster.*.private_ip)}"
    ]
  }
}

output "public_ips" {
  value = "${aws_instance.cluster.*.public_ip}"
}

output "private_ips" {
  value = "${aws_instance.cluster.*.private_ip}"
}