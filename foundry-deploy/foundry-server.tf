data "aws_ami" "this" {
  most_recent = true
  name_regex  = "amzn2-ami-kernel-*"
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.this.id
  instance_type = "t2.micro"

  tags = {
    Name = "FoundryServer"
  }
}