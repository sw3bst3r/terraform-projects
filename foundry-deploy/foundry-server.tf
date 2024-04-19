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
              sudo NEEDRESTART_MODE=a apt-get dist-upgrade --yes
              sudo apt-get update
              sudo apt-get upgrade -y
              sudo apt install -y ca-certificates curl gnupg
              sudo mkdir -p /etc/apt/keyrings
              curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
              echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
              sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
              curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
              curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
              sudo apt update
              sudo apt install nodejs caddy unzip
              cd /
              sudo rm /etc/caddy/Caddyfile
              echo "${var.top_level_domain}.${var.domain_name} {" >> /etc/caddy/Caddyfile
              echo "reverse_proxy localhost:30000" >> /etc/caddy/Caddyfile
              echo "encode zstd gzip" >> /etc/caddy/Caddyfile
              echo "}" >> /etc/caddy/Caddyfile
              sudo service caddy restart
              mkdir /home/ubuntu/foundryvtt /home/ubuntu/foundrydata /home/ubuntu/foundrydata/Config
              echo "{" >> /home/ubuntu/foundrydata/Config/aws.json
              echo "\"region\": \"us-east-1\"," >> /home/ubuntu/foundrydata/Config/aws.json
              echo "\"buckets\": [\"${var.foundry_bucket_name}\"]," >> /home/ubuntu/foundrydata/Config/aws.json
              echo "\"credentials\": {" >> /home/ubuntu/foundrydata/Config/aws.json
              echo "\"accessKeyId\": \"${aws_iam_access_key.foundry.id}\"," >> /home/ubuntu/foundrydata/Config/aws.json
              echo "\"secretAccessKey\": \"${aws_iam_access_key.foundry.secret}\"," >> /home/ubuntu/foundrydata/Config/aws.json
              echo "}" >> /home/ubuntu/foundrydata/Config/aws.json
              echo "}" >> /home/ubuntu/foundrydata/Config/aws.json
              
              cd /home/ubuntu/foundryvtt
              sudo curl -o foundryvtt.zip -L "https://github.com/sw3bst3r/terraform-projects/blob/main/foundry-deploy/foundry_zip/FoundryVTT-11.315.zip?raw=true"
              sudo unzip foundryvtt.zip
              sudo rm foundryvtt.zip
              sudo apt-get upgrade -y
              cd /home/ubuntu
              sudo 
              sudo npm install pm2 -g
              pm2 startup
              sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
              sudo chmod -R +x /home/ubuntu/foundryvtt
              sudo chmod -R +x /home/ubuntu/foundrydata
              sudo chown ubuntu -R /home/ubuntu/foundryvtt
              sudo chown ubuntu -R /home/ubuntu/foundrydata
              sudo -u ubuntu pm2 start "node /home/ubuntu/foundryvtt/resources/app/main.js --dataPath=/home/ubuntu/foundrydata" --name foundry
              sudo -u ubuntu pm2 save

              cd /home/ubuntu/foundrydata/Config
              sudo rm options.json
              sudo curl -o options.json "https://github.com/sw3bst3r/terraform-projects/blob/046bdb65f401bb8b660e337d360d8b8ce7a90108/foundry-deploy/options.json"
              pm2 restart foundry
              
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
