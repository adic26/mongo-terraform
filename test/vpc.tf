provider "aws" {
  region = "${var.region}"
}

variable "region" {
	default = "eu-west-1"
}

variable "region_number" {
  # Arbitrary mapping of region name to number to use in
  # a VPC's CIDR prefix.
  default = {
    eu-west-1      = 6
    us-east-1      = 1
    us-west-1      = 2
    us-west-2      = 3
    eu-central-1   = 4
    ap-northeast-1 = 5
  }
}

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
}

# Retrieve the AZ where we want to create network resources
# This must be in the region selected on the AWS provider.
data "aws_availability_zones" "available" {}

# Create a VPC for the region associated with the AZ
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/20"
}

# Create a subnet for the AZ within the regional VPC
resource "aws_subnet" "example" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.example.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.example.cidr_block, 4, count.index+1)}"
  tags {
    Name = "asd-${count.index}"
  }
}

output "az" {
	value = "${var.region_number[data.aws_availability_zones.available.region]}"
}