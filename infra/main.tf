provider "aws" {
  region = "us-east-1"
}

# Security Group
resource "aws_security_group" "portfolio_sg" {
  name        = "portfolio-sg"
  description = "Allow HTTP and Node backend traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t3.micro"
  key_name      = "my-key"
  vpc_security_group_ids = [aws_security_group.portfolio_sg.id]
  tags = { Name = "PortfolioServer" }

  provisioner "remote-exec" {
    inline = [
      # Update packages
      "sudo yum update -y",

      # Install dependencies
      "sudo amazon-linux-extras install epel -y",
      "sudo yum install python3-pip git -y",

      # Install Ansible on EC2
      "sudo pip3 install ansible",

      # Clone your repo (contains k8s manifests)
      "git clone https://github.com/thatoppsdev/terraform-ansible-k3s.git ~/portfolio",

      # Run Ansible playbooks from EC2
      "cd ~/portfolio/infra && ansible-playbook ../ansible/install_k3s.yml -c local",
      "cd ~/portfolio/infra && ansible-playbook ../ansible/deploy_k8s.yml -c local"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/my-key.pem")
      host        = self.public_ip
    }
  }
}

output "ec2_public_ip" {
  value = aws_instance.portfolio.public_ip
}
