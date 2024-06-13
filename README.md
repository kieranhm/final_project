# Miencraft Server 2: Fully Automated Boogaloo

So, it seems the last guy was fired for watching porn on his computer. Did he think he wouldn't get caught by info sec? I don't know, but watch porn on your own computer. In the meantime, I have a pretty cool workplace that went out of their way to set up this cool Minecraft server. He did everything manually so he should have been fired for that in my opinion. No matter, here's how to set up a Minecraft server like someone who isn't a chump who watches porn on their computer.

## What you'll need

Let's start with a list of applications you'll need:

- AWS. Good cloud computing service. Just don't leave it running or buying our own servers will become a cost cutter.

- Terraform. This is how we'll set up our infrastructure. You won't need to go into the AWS console. I've already done that multiple times (computers are dark magic and we shall never fully understand them)

- Ansible. Once we set up the infrastructure, we will need to configure the server to run on a docker script.

- GitHub. Because we want to share our gift to the world (no we're not making this server proprietary... okay, I guess I could make a couple of plugins and we can make shit tons of money off of it)

## Provisoning the Infrastructure

The first thing we're going to want to do is provision the infrastructure. Luckily, it's as simple as a terraform script. We're going to want to create the script `main.tf`

In the script, you're going to want to:

### Set terraform up to work on AWS

To do that, you're going to want to type the following into terraform. This will help you to set up AWS on Terraform.

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
```

### Create the AWS instance on Terraform

Here, you'll set up the AWS instance. You'll want to include the region. A path to your credentials is also good so you don't have to type them manually every time. Type out the following:

```
provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["path/to/credentials"]
}
```
### Create the security group

The security group will tell AWS what is allowed in and out. Since we're creating a bedrock server, we're going to want to open ports 19132 and 19133 to UDP traffic. We're also going to want to allow SSH traffic for when we use Ansible.

```
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
```

### Create an AWS key pair

For this, you'll first want to type `ssh-keygen` in the file where you want to generate your key. This will generate a public and private key. Tap three times to get the key. 

You'll also want to add the following to your terraform script:
```
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_file"
  public_key = file("path/to/key/file")
}
```

### Create the actual instance

Now that that's done, we can create the actual instance. Thankfully, we already have the security group and key set up so we just need to plug those into the right spots. Give your instance an AMI of `ami-00beae93a2d981137` which will set your server to run Ubuntu and an instance type of t2.micro

```
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
Next, we're going to want to 

### Create outputs.tf

Outputs.tf is going to output the public IP address of our server. It's going to allow us to connect to it remotely.

To do that, create an `outputs.tf` file that will print the public IP address like follows:

```
output "instance_public_ip" {
    description = "Public IP address of the EC2 instance"  
    value       = aws_instance.app_server.public_ip
}
```

You're done with Terraform! Yay! To celebrate, run `terraform init` to initialize your script and `terraform apply` to run it. If all else works, the script should run and you should see your public IP at the end.

## Configuring the Server

We are going to use an Ansible script to configure the server. Let's call this script `ansible.yml`. Our ansible script will have the following goals:

- install all required dependencies
- install docker
- add a docker image that can write Minecraft
- set up that docker image

Here, I'm going to walk you through creating the script step-by-step.

First, add three lines (`---`) to the top of the script.

Then, set the script settings:

```
- name: ansible_playbook # name of our playbook
  hosts: servers # specify the group of hosts we want to target
  gather_facts: no # do not gather data, in case python is not installed, it would fail otherwise
  become: true # elevate permission
```

We're going to start creating the tasks.

### Install The Dependencies

Before we can get anything working on our ansible script, we're going to need to install some dependencies.

Thankfully, we can create an ansible task to install those dependencies.

Write the following into `ansible.yml`:

```
- name: Update apt package cache and install dependencies
      apt:
        name: "{{ item }}"
        state: present
      with_items:
        - python3
        - apt-transport-https
        - ca-certificates
        - curl
        - software-properties-common
```

This will create a loop that will install every dependency listed here.

### Configure your script to install docker

Docker is great because you can install a Docker image with a Minecraft server and have Docker ready to go. So next, we're going to configure our script to install docker.

Configure your script to add the GPG key:

```
- name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present
```

Next, configure your script to add the docker repo:

```
- name: Add Docker repository
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable
        state: present
```

Finally, configure your script to install docker:

```
- name: Update apt and install Docker
      apt:
        name: docker-ce
        state: present
        update_cache: yes
```

Finally, we're going to want to

### Configure your script to install the Minecraft server

Now, the part we've all been waiting for

## Configure Ansible to connect to your AWS instance

Now, we're going to set ansible up to our AWS instance. Create a file called `hosts` with no extension. Open `hosts` in nano, vim, VSCode, or some other writing application.

In our ansible instance, we have our hosts set up to be `servers` so at the top of `hosts`, write `[servers]`.

Next, run `terraform apply` and copy your public IP address. Store this in `hosts` in a line under `[servers]`. Add a space and then add `ansible_user=ubuntu ansible_ssh_private_key_file=/path/to/your/key`.

All your ansible scripts should run correctly. Type `nmap -sV -Pn -p U:19132 [your public ip]` to see if it works.