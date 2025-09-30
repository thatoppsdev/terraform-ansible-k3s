provider "aws" {
  region = "us-east-1"
}

# Security Group
resource "aws_security_group" "portfolio_sg" {
  name        = "portfolio-sg"
  description = "Allow HTTP and Node backend traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node backend"
    from_port   = 3001
    to_port     = 3001
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

# EC2 Instance
resource "aws_instance" "portfolio" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t3.micro"
  key_name               = "terra"
  vpc_security_group_ids = [aws_security_group.portfolio_sg.id]
  tags                   = { Name = "PortfolioServer" }

  provisioner "remote-exec" {
    inline = [
    # Clone repo (if not already)
    "git clone https://github.com/thatoppsdev/terraform-ansible-k3s.git ~/portfolio || true",

    # Run Ansible playbooks
    "ansible-playbook ~/portfolio/ansible/install_k3s.yml -c local",
    "ansible-playbook ~/portfolio/ansible/deploy_k8s.yml -c local"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${path.module}/terra.pem")
      host        = self.public_ip
      timeout     = "15m"
    }
  }
}

output "ec2_public_ip" {
  value = aws_instance.portfolio.public_ip
}
