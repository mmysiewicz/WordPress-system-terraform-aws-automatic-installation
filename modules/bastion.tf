
data "aws_ami" "bastion_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.bastion_linux.id
  instance_type          = "t3.micro"
  subnet_id              = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name
  tags = {
    Name = "bastion-host"
  }
}
