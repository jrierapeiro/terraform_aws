resource "aws_security_group" "elb_sg" {
  name = "terraform-elb-sg"
  vpc_id = "${var.vpc_id}"
  
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

resource "aws_elb" "elb" {
  name = "terraform-elb"    
  security_groups = ["${aws_security_group.elb_sg.id}"]
  subnets = ["${var.subnet_ids}"]
  cross_zone_load_balancing = false
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  // access_logs {
    //   bucket = "s3_bucket_name"
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

  

  tags {
      Name = "terraform-elb"
  }
}

resource "aws_lb_cookie_stickiness_policy" "cookie_stickness" {
  name = "terraform-elb-cookie-stickness"
  load_balancer = "${aws_elb.elb.id}"
  lb_port = 80
  cookie_expiration_period = 600
}

output "elb_id" {
  value = "${aws_elb.elb.id}"
}

output "elb_dns" {
  value = "${aws_elb.elb.dns_name}"
}