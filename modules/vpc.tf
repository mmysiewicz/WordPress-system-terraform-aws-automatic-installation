
data "aws_availability_zones" "available" {
  state = "available"
}

# Resources
# Vpc

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "wp-vpc"
  }
}

# Igw

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "wp-igw"
  }
}

# Subnets

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = data.aws_availability_zones.available.names[index(var.public_subnets, each.value) % 2]
  map_public_ip_on_launch = true
  tags = {
    Name = "wp-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = data.aws_availability_zones.available.names[index(var.private_subnets, each.value) % 2]
  tags = {
    Name = "wp-private-${each.key}"
  }
}

# RT

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "wp-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# SG

resource "aws_security_group" "nat" {
  name   = "nat-instance-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nat-instance-sg"
  }
}

# NAT Instance

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "nat" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.nat.id]
  key_name = var.key_name
  source_dest_check = false
  tags = {
    Name = "nat-instance"
  }

user_data = <<-EOF
  #!/bin/bash

  echo 1 > /proc/sys/net/ipv4/ip_forward
  sysctl -w net.ipv4.ip_forward=1

  systemctl stop firewalld
  systemctl disable firewalld

  yum install -y iptables-services

  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
  iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables
  EOF 
}

# RT - NAT Instance 

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }
  tags = {
    Name = "wp-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = aws_route_table.private.id
}
