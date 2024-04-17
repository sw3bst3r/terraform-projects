variable "vpc_name" {
  description = "The name of the VPC to deploy the Foundry server into"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the subnet to deploy the Foundry server into"
  type        = string
}
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}
data "aws_subnet" "selected" {
  id = var.subnet_id
}