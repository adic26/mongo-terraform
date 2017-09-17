
provider "aws" {
  region = "${var.region}"
}

#data "aws_subnet_ids" "vpc" {
#  vpc_id = "${var.vpc_id}"
#}

data "aws_subnet" "vpc" {
  # hack
  count = 3
  id = "${var.subnet_ids[count.index]}"
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
  subnet_id                   = "${element(data.aws_subnet.vpc.*.id, count.index % var.zones)}"
  key_name                    = "${var.key_name}"
  count                       = "${var.servers}"
  associate_public_ip_address = true
  
  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = "${var.volume_size}"
    volume_type = "${var.volume_type}"
    iops        = "${var.volume_iops}"
  }
 
  tags {
    Name       = "${var.tag_name}-${count.index}"
    owner      = "${var.owner}"
    expire-on  = "${var.expire_on}"
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
}

output "public_ips" {
  value = "${aws_instance.cluster.*.public_ip}"
}

output "private_ips" {
  value = "${aws_instance.cluster.*.private_ip}"
}

output "instance_ids" {
  value = "${join("\n", aws_instance.cluster.*.instance_id)}"
}