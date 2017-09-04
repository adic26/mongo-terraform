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
  cidr_block = "10.0.0.0/20"
  tags {
    Name = "example-vpc"
  }
}

# e.g. Create subnets in the first two available availability zones
resource "aws_subnet" "primary" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  tags {
    Name = "example-primary"
  }
}

resource "aws_subnet" "secondary" {
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  tags {
    Name = "example-secondary"
  }
}

resource "aws_subnet" "tertiary" {
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"
  tags {
    Name = "example-tertiary"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
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

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "main"
  }
}

resource "aws_route" "r" {
  route_table_id            = "${data.aws_route_table.main.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main.id}"
}

