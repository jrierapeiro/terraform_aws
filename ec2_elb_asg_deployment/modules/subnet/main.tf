resource "aws_subnet" "subnet" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "${var.subnet_cidr}"
    availability_zone = "${var.availability_zone}"

    tags {
        Name = "Subnet"
    }
}

resource "aws_route_table_association" "association" {
    subnet_id = "${aws_subnet.subnet.id}"
    route_table_id = "${var.route_table_id}"
} 

output "subnet_id" {
  value = "${aws_subnet.subnet.id}"
}