provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr_block" {
}
variable "subnet_cidr_block" {
}
variable "availability_zone" {
}
variable "env_prefix" {
}
variable "environment" {
  description = "deployment environment"
}

resource "aws_vpc" "application-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
    ENV : var.environment
  }
}

resource "aws_subnet" "application-subnet-1" {
  vpc_id            = aws_vpc.application-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}


resource "aws_internet_gateway" "application-internet-gateway" {
  vpc_id = aws_vpc.application-vpc.id
  tags = {
    Name : "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "application-default-rtb" {
  default_route_table_id = aws_vpc.application-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.application-internet-gateway.id
  }
  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
}

output "vpc-id" {
  value = aws_vpc.application-vpc.id
}
output "subnet-id" {
  value = aws_subnet.application-subnet-1.id
}