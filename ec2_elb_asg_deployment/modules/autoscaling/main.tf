data "template_file" "linux_user_data" {
  template = "${file("linux_user_data.txt")}"  
}

resource "aws_launch_configuration" "nodejs_app" {
    image_id = "${var.linux_ami}"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    security_groups = ["${var.sg_id}"]
    user_data = "${data.template_file.linux_user_data.rendered}" 
    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "nodejs_app_asg" {
    name = "terraform_nodejs-linux-asg"
    launch_configuration = "${aws_launch_configuration.nodejs_app.name}"
    max_size = "${var.max_size}"
    min_size = "${var.min_size}"
    desired_capacity = "${var.desired_capacity}"    
    enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
    vpc_zone_identifier = ["${var.subnet_ids}"]
    load_balancers = ["${var.elb_ids}"]
    health_check_type = "ELB"

    tag {
        key = "Name"
        value = "nodejs-linux-asg"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_policy" "autopolicy" {
    name = "terraform-autoplicy"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.nodejs_app_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
    alarm_name = "terraform-cpu-alarm"
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

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_down" {
    alarm_name = "terraform-cpu-alarm-down"
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