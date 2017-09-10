
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

resource "aws_ebs_volume" "data-volumes" {
  availability_zone = "${element(data.aws_subnet.vpc.*.availability_zone, count.index % var.zones)}"
  size              = "${var.volume_size}"
  type              = "${var.volume_type}"
  iops              = "${var.volume_iops}"
  count             = "${var.servers}"
  tags {
    Name       = "${var.tag_name}-${count.index}"
    owner      = "${var.owner}"
  }  
}

resource "aws_spot_instance_request" "cluster" {
  ami                         = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  vpc_security_group_ids      = ["${var.security_group}"]
  subnet_id                   = "${element(data.aws_subnet.vpc.*.id, count.index % var.zones)}"
  key_name                    = "${var.key_name}"
  count                       = "${var.servers}"
  wait_for_fulfillment        = true
  spot_price                  = "${var.spot_price}"  
  associate_public_ip_address = true
  
  #ebs_block_device {
  #  device_name = "/dev/xvdb"
  #  volume_size = "${var.volume_size}"
  #  volume_type = "${var.volume_type}"
  #  iops        = "${var.volume_iops}"
  #}
 
  tags {
    Name       = "${var.tag_name}-${count.index}"
    owner      = "${var.owner}"
    expire-on  = "${var.expire_on}"
  }
}

resource "aws_volume_attachment" "data" {
  device_name       = "/dev/xvdb"
  volume_id         = "${element(aws_ebs_volume.data-volumes.*.id, count.index)}"
  instance_id       = "${element(aws_spot_instance_request.cluster.*.spot_instance_id, count.index)}"
  count             = "${var.servers}"
}

resource "null_resource" "configure" {
  count = "${var.servers}"
  
  triggers {
    volume_attachment = "${join(",", aws_volume_attachment.data.*.id)}"
  }

  connection {
    host = "${element(aws_spot_instance_request.cluster.*.public_ip, count.index)}"
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
  value = "${aws_spot_instance_request.cluster.*.public_ip}"
}

output "private_ips" {
  value = "${aws_spot_instance_request.cluster.*.private_ip}"
}

output "instance_ids" {
  value = "${join("\n", aws_spot_instance_request.cluster.*.spot_instance_id)}"
}