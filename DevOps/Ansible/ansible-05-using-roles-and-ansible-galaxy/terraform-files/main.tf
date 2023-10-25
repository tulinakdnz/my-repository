//This Terraform Template creates 3 Ansible Machines on EC2 Instances
//Ansible Machines will run on Amazon Linux 2, Red Hat Enterprise Linux 8 and Ubuntu 20.04 with custom security group
//allowing SSH (22) and HTTP (80) connections from anywhere.
//User needs to select appropriate variables form "tfvars" file when launching the instance.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  #  secret_key = ""
  #  access_key = ""
}

resource "aws_instance" "nodes" {
  ami = element(var.myami, count.index)
  instance_type = "${count.index == 0 ? var.control-node-type : var.worker-node-type}"
  count = var.num
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  tags = {
    Name = element(var.tags, count.index)
  }
}

data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "tf-sec-gr" {
  name = var.mysecgr
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = var.mysecgr
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

resource "null_resource" "config" {
  depends_on = [aws_instance.nodes[0]]
  connection {
    host = aws_instance.nodes[0].public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/${var.mykey}.pem")
    # Do not forget to define your key file path correctly!
  }

  provisioner "file" {
    source = "./ansible.cfg"
    destination = "/home/ec2-user/.ansible.cfg"
  }

  provisioner "file" {
    # Do not forget to define your key file path correctly!
    source = "~/.ssh/${var.mykey}.pem"
    destination = "/home/ec2-user/${var.mykey}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname Control-Node",
      "sudo dnf update -y",
      "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py",
      "python3 get-pip.py --user",
      "pip3 install --user ansible",
      "echo [servers] > inventory.txt",
      "echo web_server_1 ansible_host=${aws_instance.nodes[1].private_ip}  ansible_ssh_private_key_file=~/${var.mykey}.pem  ansible_user=ec2-user >> inventory.txt",
      "echo web_server_2  ansible_host=${aws_instance.nodes[2].private_ip}  ansible_ssh_private_key_file=~/${var.mykey}.pem  ansible_user=ubuntu >> inventory.txt",
      "chmod 400 ${var.mykey}.pem"
    ]
  }

}

output "controlnodeip" {
  value = aws_instance.nodes[0].public_ip
}

output "privates" {
  value = aws_instance.nodes.*.private_ip
}
