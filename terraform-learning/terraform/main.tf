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

resource "aws_security_group" "app-sg" {
  name        = "${var.env_prefix}-app-sg"
  description = "Allow inbound traffic from ssh"
  vpc_id      = aws_vpc.application-vpc.id

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name : "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "myapp-server" {
  ami                    = data.aws_ami.latest-amazon-linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.application-subnet-1.id
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  availability_zone      = var.availability_zone
  associate_public_ip_address = true

  tags = {
    Name : "${var.env_prefix}-app-server"
  }
}

output "aws-ami" {
  value = data.aws_ami.latest-amazon-linux.id
}
output "vpc-id" {
  value = aws_vpc.application-vpc.id
}
output "subnet-id" {
  value = aws_subnet.application-subnet-1.id
}
