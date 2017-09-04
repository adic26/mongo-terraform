
provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "server" {
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
  
  # copy provisioning files to /tmp
  provisioner "file" {
    source = "${path.module}/scripts"
    destination = "/tmp"
  }

  # move ulimit file to /etc
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/scripts/99-mongodb-nproc.conf /etc/security/limits.d"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.servers} > /tmp/instance-number.txt"
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/provision.sh"
    ]
  }  
  
  tags {
    Name       = "${var.tag_name}-${count.index}"
	  owner      = "${var.owner}"
	  expire-on  = "${var.expire_on}"
  }
}

