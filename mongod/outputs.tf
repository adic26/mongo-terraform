output "public_ips" {
  value = "${aws_instance.cluster.*.public_ip}"
}

output "private_ips" {
  value = "${aws_instance.cluster.*.private_ip}"
}