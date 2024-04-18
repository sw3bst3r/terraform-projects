data "aws_ami" "this" {
  most_recent = true
  name_regex  = "ubuntu/images/hvm-ssd/ubuntu-jammy-*"
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "instance_kp_name" {
  description = "The name of the key pair to use for the Foundry server instance"
  type        = string
}

data "aws_key_pair" "this" {
  key_name = var.instance_kp_name
}

variable "instance_type" {
  description = "The instance type to use for the Foundry server"
  type        = string
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.this.id
  associate_public_ip_address = true
  instance_type = var.instance_type
  vpc_security_group_ids = [
    aws_security_group.this.id
  ]
  key_name  = data.aws_key_pair.this.key_name
  subnet_id = data.aws_subnet.selected.id
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              cd /
              mkdir /foundry /foundry/data /foundry/data/Config
              echo "{" >> /foundry/data/Config/aws.json
              echo "\"region\": \"us-east-1\"," >> /foundry/data/Config/aws.json
              echo "\"buckets\": [\"${var.foundry_bucket_name}\"]," >> /foundry/data/Config/aws.json
              echo "\"credentials\": {" >> /foundry/data/Config/aws.json
              echo "\"accessKeyId\": \"${aws_iam_access_key.foundry.id}\"," >> /foundry/data/Config/aws.json
              echo "\"secretAccessKey\": \"${aws_iam_access_key.foundry.secret}\"," >> /foundry/data/Config/aws.json
              echo "}" >> /foundry/data/Config/aws.json
              echo "}" >> /foundry/data/Config/aws.json

              EOF

  tags = {
    Name = "FoundryServerV2"
  }
}

resource "aws_security_group" "this" {
  name        = "foundry-server-sg"
  description = "Allow inbound SSH, HTTP, and HTTPS traffic"
  vpc_id     = data.aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_foundry_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 30000
  ip_protocol       = "tcp"
  to_port           = 30000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

## We are not using IPv6 in this project, so we will comment out the following code

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv6" {
#   security_group_id = aws_security_group.this.id
#   cidr_ipv6         = data.aws_vpc.main.ipv6_cidr_block
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }
# resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv6" {
#   security_group_id = aws_security_group.this.id
#   cidr_ipv6         = data.aws_vpc.main.ipv6_cidr_block
#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80
# }
# resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv6" {
#   security_group_id = aws_security_group.this.id
#   cidr_ipv6         = data.aws_vpc.main.ipv6_cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }
# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.this.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }
