//This Terraform Template creates 4 Ansible Machines on EC2 Instances
//Ansible Machines will run on Amazon Linux 2023 and Ubuntu 22.04 with custom security group
//allowing SSH (22) and HTTP (80) connections from anywhere.
//User needs to select appropriate key name when launching the instance.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # secret_key = ""
  # access_key = ""
}


resource "aws_instance" "amazon-linux-2" {
  ami = var.amznlnx2023
  instance_type = var.instype
  count = 3
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  tags = {
    Name = element(var.tags, count.index)
  }
}


resource "aws_instance" "ubuntu" {
  ami = var.ubuntu
  instance_type = var.instype
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]

tags = {
  Name = "node_3"
}
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "tf-sec-gr" {
  name = "ansible-session-sec-gr-${var.user}"
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = "ansible-session-sec-gr"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

