# -----------------------------
# Terraform: AWS HPC Simulated Cluster
# -----------------------------

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "hpc_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "hpc_subnet" {
  vpc_id                  = aws_vpc.hpc_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "hpc_sg" {
  name        = "hpc_sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.hpc_vpc.id

  ingress {
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
}

resource "aws_instance" "gpu_node" {
  ami                    = "ami-0c4f7023847b90238" # Deep Learning Base AMI (Ubuntu 20.04)
  instance_type          = "g5.xlarge"              # GPU enabled
  subnet_id              = aws_subnet.hpc_subnet.id
  vpc_security_group_ids = [aws_security_group.hpc_sg.id]
  key_name               = "your-key-name"

  tags = {
    Name = "hpc-gpu-node"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update && apt install -y docker.io nvidia-driver-470
              systemctl enable docker
              reboot
              EOF
}

resource "aws_instance" "controller" {
  ami                    = "ami-0c4f7023847b90238"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.hpc_subnet.id
  vpc_security_group_ids = [aws_security_group.hpc_sg.id]
  key_name               = "your-key-name"

  tags = {
    Name = "hpc-controller"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update && apt install -y slurm-wlm munge nfs-common
              systemctl enable slurmctld
              EOF
}

