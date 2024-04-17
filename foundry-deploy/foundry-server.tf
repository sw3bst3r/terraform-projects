data "aws_ami" "this" {
  most_recent = true
  name_regex  = "amzn2-ami-kernel-*"
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
  instance_type = var.instance_type
  security_groups = [
    aws_security_group.this.id
  ]
  key_name  = data.aws_key_pair.this.key_name
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              echo "{" >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "\"region\": \"us-east-1\"," >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "\"buckets\": [\"${var.foundry_bucket_name}\"]," >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "\"credentials\": {" >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "\"accessKeyId\": \"${aws_iam_access_key.foundry.id}\"," >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "\"secretAccessKey\": \"${aws_iam_access_key.foundry.secret}\"," >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "}" >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json
              echo "}" >> ~/.local/share/FoundryVTT/foundrydata/Config/aws.json

              EOF

  tags = {
    Name = "FoundryServer"
  }
}

resource "aws_security_group" "this" {
  name        = "foundry-server-sg"
  description = ""
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
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
