provider "aws" {
  region = "us-east-1"
}

variable "cidr-blocks" {
  description = "cidr blocks for vpc and subnets"
  type = list(object({
    cidr-block = string
    name = string
  }))
}
# variable "vpc-cidr-block" {
#   description = "vpc cidr block"
# }
variable "environment" {
  description = "deployment environment"
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr-blocks[0].cidr-block
  tags = {
    Name : var.cidr-blocks[0].name,
    ENV : var.environment
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id            = aws_vpc.development-vpc.id
  cidr_block        = var.cidr-blocks[1].cidr-block
  availability_zone = "us-east-1a"
  tags = {
    Name : var.cidr-blocks[1].name
  }
}

output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}
output "dev-subnet-id" {
  value = aws_subnet.dev-subnet-1.id
}