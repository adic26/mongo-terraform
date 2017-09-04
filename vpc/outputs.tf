output "security_group" {
    value = "${aws_security_group.main.id}"
}

output "subnet_id" {
    value = "${aws_subnet.primary.id}"
}