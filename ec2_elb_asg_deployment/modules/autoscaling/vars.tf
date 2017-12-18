variable "linux_ami" {
  description = "The linux ami"  
}

variable "aws_key_name" {
  description = "The key name for the ec2 instance"  
}

variable "sg_id" {
  description = "The security group id for the ec2 instance"  
}

variable "subnet_ids" {
  description = "The Subnet ids"  
}

variable "elb_ids" {
  description = "The ebl ids"  
}

variable "max_size" {
  description = "The max size of ec2 instances"  
}

variable "min_size" {
  description = "The min size of ec2 instances"  
}

variable "desired_capacity" {
  description = "The desired capacity of ec2 instances"  
}