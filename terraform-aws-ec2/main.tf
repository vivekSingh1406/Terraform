# Security Group
resource "aws_security_group" "ec2_sg" {

  name        = "my-ec2-security-group"
  description = "Allow SSH and HTTP"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2
resource "aws_instance" "my_ec2" {

  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"

  # Use SG ID
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  # Make sure EC2 gets public IP
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Install Nginx
  user_data = <<-EOF
    #!/bin/bash

    dnf update -y
    dnf install -y nginx

    systemctl enable nginx
    systemctl start nginx

    echo '<h1>Hello From Terraform EC2</h1>' > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name        = "Terraform-EC2"
    Environment = "Development"
    Project     = "Terraform-Learning"
  }
}

output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

output "ec2_instance_id" {
  value = aws_instance.my_ec2.id
}