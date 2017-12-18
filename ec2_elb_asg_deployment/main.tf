module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "${var.vpc_cidr}"
}

module "subnet" {
  source = "./modules/subnet"
  vpc_id = "${module.vpc.vpc_id}"
  route_table_id = "${module.vpc.rt_id}"
  subnet_cidr = "${var.public_subnet_cidr}"
  availability_zone = "eu-west-1a"
}

module "public_security_group_web" {
  source = "./modules/public_security_group_web"
  vpc_id = "${module.vpc.vpc_id}"
} 

module "elb" {
  source = "./modules/elb"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.subnet.subnet_id}"
}

module "autoscaling" {
  source = "./modules/autoscaling"
  linux_ami = "${var.linux_ami}"
  aws_key_name = "${var.aws_key_name}"
  sg_id = "${module.public_security_group_web.sg_id}"
  subnet_ids = "${module.subnet.subnet_id}"
  elb_ids = "${module.elb.elb_id}"
  max_size = 3
  min_size = 1
  desired_capacity = 2
}

output "elb_dns" {
  value = "${module.elb.elb_dns}"
}