provider "aws" {
  region = "${var.region}"
}

# get the most recent amazon linux ami
data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # amazon
}

resource "aws_instance" "server" {
  ami                         = "${data.aws_ami.linux.id}"
  instance_type               = "${var.instance_type}"
  vpc_security_group_ids      = ["${var.security_group}"]
  subnet_id                   = "${var.subnet_id}"
  key_name                    = "${var.key_name}"
  count                       = "${var.servers}"  
  associate_public_ip_address = true
  
  #ebs_block_device {
  #  device_name = "/dev/sdb"
  #   volume_size = "${var.ebs_size}"
  #}
  
  connection {
     user = "${lookup(var.user, var.platform)}"
     private_key = "${file("${var.key_path}")}"
  }
  
  provisioner "file" {
    source = "${path.module}/../shared/scripts/99-mongodb-nproc.conf"
    destination = "/etc/security/limits.d/99-mongodb-nproc.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers} > /tmp/consul-server-count",
      "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../shared/scripts/provision.sh"
    ]
  }  
  
  tags {
    Name       = "${var.tag_name}-${count.index}"
	owner      = "${var.owner}"
	expire-on  = "${var.expire_on}"
  }
}

