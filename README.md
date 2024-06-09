# Miencraft Server 2: Fully Automated Boogaloo

So, it seems the last guy was fired for watching porn on his computer. Did he think he wouldn't get caught by info sec? I don't know, but watch porn on your own computer. In the meantime, I have a pretty cool workplace that went out of their way to set up this cool Minecraft server. He did everything manually so he should have been fired for that in my opinion. No matter, here's how to set up a Minecraft server like someone who isn't a chump who watches porn on their computer.

## What you'll need

Let's start with a list of applications you'll need:

- AWS. Good cloud computing service. Just don't leave it running or buying our own servers will become a cost cutter.

- Terraform. This is how we'll set up our infrastructure. You won't need to go into the AWS console. I've already done that multiple times (computers are dark magic and we shall never fully understand them)

- Ansible. Once we set up the infrastructure, we will need to configure the server to run on a docker script.

- GitHub. Because we want to share our gift to the world (no we're not making this server proprietary... okay, I guess I could make a couple of plugins and we can make shit tons of money off of it)

## Provisoning the Infrastructure

The first thing we're going to want to do is provision the infrastructure. Luckily, it's as simple as a terraform script. We're going to want two terraform scripts:
- `main.tf`
- `outputs.tf`

We're also going to want to create two files in folders in our terraform script:

I've already written them so I'll just copy paste the contents in here.

`main.tf`. This is the script that will help us set up our infrastructure.
```
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
  shared_credentials_files = ["path/to/credentials"]
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
  public_key = file("path/to/key/file")
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
```

`outputs.tf`. This is the script which will output our public IP address. We're going to want to use this so that our Ansible script can ssh into our server and provision everything.
```
output "instance_public_ip" {
    description = "Public IP address of the EC2 instance"  
    value       = aws_instance.app_server.public_ip
}
```
Good? Good. Now let's move onto

## Configuring the Server

We are going to use an Ansible script to configure the server.