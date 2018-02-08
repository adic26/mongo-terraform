
provider "aws" {
  region = "${var.region}"
}

data "aws_subnet" "vpc" {
  count = "${var.zones}"
  id = "${var.subnet_ids[count.index]}"
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
}

output "public_ips" {
  value = "${aws_spot_instance_request.cluster.*.public_ip}"
}

output "private_ips" {
  value = "${aws_spot_instance_request.cluster.*.private_ip}"
}

output "instance_ids" {
  value = "${join("\n", aws_spot_instance_request.cluster.*.spot_instance_id)}"
}

output "volume_ids" {
  value = "${aws_volume_attachment.data.*.id}"
}