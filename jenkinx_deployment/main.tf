resource "aws_vpc" "con_dep_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "terraform-aws-vpc"
    }
}

resource "aws_internet_gateway" "con_dep_igw" {
    vpc_id = "${aws_vpc.con_dep_vpc.id}"
}

resource "aws_subnet" "con_dep_eu-west-1a-public" {
    vpc_id = "${aws_vpc.con_dep_vpc.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "eu-west-1a"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "con_dep_eu-west-1a-public_route_table" {
    vpc_id = "${aws_vpc.con_dep_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.con_dep_igw.id}"
    }

    tags {
        Name = "Public Route"
    }
}

resource "aws_route_table_association" "eu-west-1a-public" {
    subnet_id = "${aws_subnet.con_dep_eu-west-1a-public.id}"
    route_table_id = "${aws_route_table.con_dep_eu-west-1a-public_route_table.id}"
}


resource "aws_security_group" "con_dep_sg_web" {
    name = "public_sg"
    description = "Allow traffic from internet web on port 3000 and ssh"   

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
   
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.con_dep_vpc.id}"

    tags {
        Name = "Public Web SG"
    }
}

data "template_file" "jenkins_user_data" {
  template = "${file("jenkins_user_data.txt")}"  
}

resource "aws_instance" "linux-ec2" {
    ami = "${var.linux_ami}"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.con_dep_sg_web.id}"]
    subnet_id = "${aws_subnet.con_dep_eu-west-1a-public.id}"
    associate_public_ip_address = true
    user_data = "${data.template_file.jenkins_user_data.rendered}"
    iam_instance_profile="Deployment-role"
    
    tags {
        Name = "Jenkins EC2"
    }
}
