
#instance
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}



#ec2.tf
resource "aws_instance" "lab-bastion-host" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public-subnet-a.id
    associate_public_ip_address = true
    key_name = aws_key_pair.hk_keypair.key_name
    vpc_security_group_ids = [aws_security_group.lab-bastion-sg.id]

    tags = {
        Name = "lab-bastion-host"
    }

}


#SG - bastion
resource "aws_security_group" "lab-bastion-sg" {
  name        = "lab-bastion_sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.lab-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
}

#SG - appserver
resource "aws_security_group" "lab-appserver-sg" {
  name        = "lab-appserver-sg"
  description = "Allow RDS(8000port), SSH(22port) and HTTP(80port)"
  vpc_id      = aws_vpc.lab-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
}
