provider "aws" {
  region = "ap-northeast-1"
}

# resource "aws_vpc" "example_vpc" {
#   cidr_block = "10.0.0.0/16"
#
#   tags = {
#     Name = "sunaga"
#   }
# }
#
# resource "aws_subnet" "example_subnet" {
#   vpc_id     = aws_vpc.example_vpc.id
#   cidr_block = "10.0.0.0/24"
#
#   tags = {
#     Name = "sunaga"
#   }
# }

resource "aws_security_group" "sg_instance" {
  name = "sunaga-example-instance"
  # vpc_id = aws_vpc.example_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0f415cc2783de6675"
  instance_type = "t2.micro"
  # subnet_id                   = aws_subnet.example_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_instance.id]
  # associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash
  echo "hello world" > index.html
  nohup busybox httpd -f -p 8080 &
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "sunaga-example"
  }
}
