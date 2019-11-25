# --------------------------------------------------------------------------------------------------
# Terraform scenary for ADV-it challenge 1 
# Author: Dmitry Lavrukhin
#
# Version      Date           Name                Info
# 0.1          19-Nov-2019    Dmitry Lavrukhin    Initial Version
#
# Requirements:
# please set this environment variables before apply:
# ---windows example:
# set AWS_ACCESS_KEY_ID=REPLACE_ME
# set AWS_SECRET_ACCESS_KEY=REPLACE_ME
# ---windows PowerShell example:
# $env:AWS_ACCESS_KEY_ID="REPLACE_ME"
# $env:AWS_SECRET_ACCESS_KEY="REPLACE_ME"
# ---linux example:
# export AWS_ACCESS_KEY_ID=REPLACE_ME
# export AWS_SECRET_ACCESS_KEY=REPLACE_ME
#
# also set variable parameters in file terraform.tfvars.example and rename it to terraform.tfvars
# --------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.region
}

data "template_file" "myuserdata" {
  template = "${file("${path.cwd}/myuserdata.tpl")}"
}

variable "region" {
  type = string
}

variable "keypair_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

resource "aws_eip" "advit" {
  vpc = true
  tags = {
    Owner = "Dmitry Lavrukhin"
    Project = "ADV-IT challenge1"
  } 
}

resource "aws_iam_instance_profile" "profile" {
  name = "ec2allowattacheip"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "ec2allowattacheip"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy" {
  name = "ec2allowattacheip"
  role = aws_iam_role.role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AssociateAddress",
                "ec2:DescribeAddresses",
                "ec2:DescribeTags",
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_security_group" "sshonly" {
  name        = "allow_ssh_only"
  description = "Allow only ssh inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
}
}

resource "aws_launch_template" "advit" {
  name   = "advit-challenge1-template"
  description = "launch template for running amazon linux autoscaling group ADV-IT challenge 1"
  image_id      = "ami-0f3a43fbf2d3899f7"
  instance_type = var.instance_type
  key_name = var.keypair_name
  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.sshonly.id]
    delete_on_termination = true
  }
  tags = {
    Name = "advit-challenge1-template"
    Owner = "Dmitry Lavrukhin"
    Project = "ADV-IT challenge1"
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "adv-it challenge1 instance"
      Owner = "Dmitry Lavrukhin"
      Project = "ADV-IT challenge1"
      } 
  }
  user_data = base64encode(data.template_file.myuserdata.template)
}

resource "aws_autoscaling_group" "advit" {
  name = "ADV-IT challenge1 group"
  availability_zones = ["eu-central-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  health_check_grace_period = 180
  default_cooldown = 180
  vpc_zone_identifier = var.subnets
  launch_template {
    id      = aws_launch_template.advit.id
    version = "$Latest"
  }
  tags = [
  {
    key = "Name"
    value = "advit challenge1"
    propagate_at_launch = false
  },
  {
    key = "Owner"
    value = "Dmitry Lavrukhin"
    propagate_at_launch = true
  },
  {
    key = "Project"
    value = "ADV-IT challenge1"
    propagate_at_launch = true
  }
  ]
}
