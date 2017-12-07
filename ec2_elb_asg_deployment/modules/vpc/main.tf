resource "aws_vpc" "testing_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "terraform-aws-vpc"
    }
}

resource "aws_internet_gateway" "testing_igw" {
    vpc_id = "${aws_vpc.testing_vpc.id}"
}

resource "aws_route_table" "testing_route_table" {
    vpc_id = "${aws_vpc.testing_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.testing_igw.id}"
    }

    tags {
        Name = "Public Route"
    }
}

output "vpc_id" {
  value = "${aws_vpc.testing_vpc.id}"
}

output "igw_id" {
  value = "${aws_internet_gateway.testing_igw.id}"
}

output "rt_id" {
  value = "${aws_route_table.testing_route_table.id}"
}