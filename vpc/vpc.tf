provider "aws" {
  region = "${var.region}"
}

# Declare the data source
data "aws_availability_zones" "available" {}

# Fish out the route table created with the internet gateway
data "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

# Create a VPC for the region associated with the AZ
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/20"
  enable_dns_hostnames = true
  tags {
    Name = "${var.tag_name}-vpc"
  }
}

resource "aws_subnet" "main" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 4, count.index+1)}"
  tags {
    Name = "${var.tag_name}-${count.index}"
  }
}

resource "aws_security_group" "mongo" {
  name        = "${var.tag_name}-mongo-sg"
  description = "open mongo outbound"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
	self        = true
  }  

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "opsmgr" {
  name        = "${var.tag_name}-opsmgr-sg"
  description = "open opsmgr outbound"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
	self        = true
  }  

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.tag_name}"
  }
}

resource "aws_route" "r" {
  route_table_id            = "${data.aws_route_table.main.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main.id}"
}

output "mongo_sg" {
    value = "${aws_security_group.mongo.id}"
}

output "opsmgr_sg" {
    value = "${aws_security_group.opsmgr.id}"
}

output "subnet_ids" {
    value = "${aws_subnet.main.*.id}"
}

output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

#output "subnet_zones" {
#    value = #["${aws_subnet.primary.availability_zone}","${aws_subnet.secondary.availability_zone}","${aws_subnet.tertiary.availability_zone}"]
#}