variable "vpc_name" {
  description = "The name of the VPC to deploy the Foundry server into"
  type        = string
}
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}