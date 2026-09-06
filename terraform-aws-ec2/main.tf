# Security Group
resource "aws_security_group" "ec2_sg" {

  name = "my-ec2-security-group"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "my_ec2" {

  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"

  security_groups = [
    aws_security_group.ec2_sg.name
  ]

  # Root disk
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

    echo "<h1>Hello From Terraform EC2</h1>" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name        = "Terraform-EC2"
    Environment = "Development"
    Project     = "Terraform-Learning"
  }
}

# Output Public IP
output "ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

# Output Instance ID
output "ec2_instance_id" {
  value = aws_instance.my_ec2.id
}
