terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region = "us-east-1"
  shared_credentials_files = [".aws/credentials"]
}
resource "aws_security_group" "my_security_group" {
  name        = "my_security_group"
  description = "Example security group for AWS instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add more ingress rules as needed

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_file"
  public_key = file(".ssh/id_ed25519.pub")
}
resource "aws_instance" "app_server" {
  ami           = "ami-00beae93a2d981137"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  security_groups = [aws_security_group.my_security_group.name]
  tags = {
    Name = "MinecraftServer"
  }
}