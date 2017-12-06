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

resource "aws_subnet" "testing_eu-west-1a-public" {
    vpc_id = "${aws_vpc.testing_vpc.id}"
    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "eu-west-1a"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "testing_eu-west-1a-public_route_table" {
    vpc_id = "${aws_vpc.testing_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.testing_igw.id}"
    }

    tags {
        Name = "Public Route"
    }
}

resource "aws_route_table_association" "eu-west-1a-public" {
    subnet_id = "${aws_subnet.testing_eu-west-1a-public.id}"
    route_table_id = "${aws_route_table.testing_eu-west-1a-public_route_table.id}"
}   

resource "aws_security_group" "testing_sg_web" {
    name = "terraform_public_sg"
    description = "Allow traffic from internet web on port 80"   
    vpc_id = "${aws_vpc.testing_vpc.id}"

    ingress {
        from_port = 3000
        to_port = 3000
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
        from_port = 3000
        to_port = 3000
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

    tags {
        Name = "Public Web SG"
    }
}

data "template_file" "linux_user_data" {
  template = "${file("linux_user_data.txt")}"  
}

resource "aws_launch_configuration" "nodejs_app" {
    image_id = "${var.linux_ami}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.testing_sg_web.id}"]
    // associate_public_ip_address = true
    user_data = "${data.template_file.linux_user_data.rendered}" 
    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "nodejs_app_asg" {
    name                 = "terraform_nodejs-linux-asg"
    launch_configuration = "${aws_launch_configuration.nodejs_app.name}"
    max_size                  = 3
    min_size                  = 1
    desired_capacity    =1    
    enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
    vpc_zone_identifier = ["${aws_subnet.testing_eu-west-1a-public.id}"]
    load_balancers= ["${aws_elb.elb1.id}"]
    health_check_type="ELB"

    tag {
        key = "Name"
        value = "nodejs-linux-asg"
        propagate_at_launch = true
    }
}

resource "aws_security_group" "elbsg" {
    name = "terraform_security_group_for_elb"
    vpc_id = "${aws_vpc.testing_vpc.id}"
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 3000
        to_port = 3000
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
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_elb" "elb1" {
    name = "terraform-elb"
    //availability_zones        =  "eu-west-1a"//, "eu-west-1b", "eu-west-1c"
    security_groups = ["${aws_security_group.elbsg.id}"]
    subnets = ["${aws_subnet.testing_eu-west-1a-public.id}"]
   // access_logs {
     //   bucket = "elb-log.davidwzhang.com"
       // bucket_prefix = "elb"
       // interval = 5
    //}
    listener {
        instance_port = 3000
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }
    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:3000/"
        interval = 30
    }

    cross_zone_load_balancing = false
    idle_timeout = 400
    connection_draining = true
    connection_draining_timeout = 400

    tags {
        Name = "terraform-elb"
    }
}

resource "aws_lb_cookie_stickiness_policy" "cookie_stickness" {
    name = "cookiestickness"
    load_balancer = "${aws_elb.elb1.id}"
    lb_port = 80
    cookie_expiration_period = 600
}

resource "aws_autoscaling_policy" "autopolicy" {
    name = "terraform-autoplicy"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.nodejs_app_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm" {
    alarm_name = "terraform-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "60"

    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.nodejs_app_asg.name}"
    }

    alarm_description = "This metric monitor EC2 instance cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.autopolicy.arn}"]
}

resource "aws_autoscaling_policy" "autopolicy-down" {
    name = "terraform-autoplicy-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.nodejs_app_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
    alarm_name = "terraform-alarm-down"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "10"

    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.nodejs_app_asg.name}"
    }

    alarm_description = "This metric monitor EC2 instance cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.autopolicy-down.arn}"]
}

output "elb-dns" {
    value = "${aws_elb.elb1.dns_name}"
}