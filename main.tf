# -----------------------------------------------------------
# Provider

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 2.70"
        }
    }
}

provider "aws" {
    profile = "default"
    region  = "eu-west-1"
}

# -----------------------------------------------------------
# Create the keypair which will be used to connect to the EC2 instance

resource "aws_key_pair" "tf-key-pair" {
key_name = "${var.github_nickname}_key_pair"
public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}

resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair"
}


# -----------------------------------------------------------
#Create the Security Group to allow HTTP and SSH traffic
resource "aws_security_group" "sg-ec2" {
    name        = "sg"

    ingress {
        description = "HTTP from everywhere"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    ingress {
        description = "HTTP from everywhere"
        from_port   = 5000
        to_port     = 5000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH from everywhere"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "TutorialSG"
    }
}

resource "aws_instance" "servers" {
    count               = 2
    ami                 = "ami-0da36f7f059b7086e" // Ubuntu 20.04
    instance_type       = "t2.micro"
    key_name            = "${var.github_nickname}_key_pair"

    security_groups = [aws_security_group.sg-ec2.name]

    tags = {
        Name = "${var.github_nickname}_key_pair${count.index}"
    }
}


output "public_ips" {
    value = "${aws_instance.servers.*.public_ip}"
}


output "public_dns" {
    value = "${aws_instance.servers.*.public_dns}"
}

