variable "aws_secret_key" {}
variable "aws_access_key" {}
variable "aws_key_name" {}

variable "aws_region" {
  description = "EC2 Region for the VPC"
  default = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0.0.0/24"
}

variable "linux_ami" {
    description = "Amazon Linux AMI 2017.09.1.20171120 x86_64 HVM GP2"
    default = "ami-1a962263"
}