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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "sg_instance" {
  name = "sunaga-example-instance"
  # vpc_id = aws_vpc.example_vpc.id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_instance" "example" {
resource "aws_launch_configuration" "example" {
  # ami           = "ami-0f415cc2783de6675" # for aws_instance
  image_id      = "ami-0f415cc2783de6675"
  instance_type = "t2.micro"
  # subnet_id                   = aws_subnet.example_subnet.id # for aws_instance
  # vpc_security_group_ids = [aws_security_group.sg_instance.id] # for aws_instance
  security_groups = [aws_security_group.sg_instance.id]
  # associate_public_ip_address = true # for aws_instance

  user_data = <<-EOF
  #!/bin/bash
  echo "hello world" > index.html
  nohup busybox httpd -f -p ${var.server_port} &
  EOF

  lifecycle {
    create_before_destroy = true
  }

  # user_data_replace_on_change = true # for aws_instance

  # tags = { # for aws_instance
  #   Name = "sunaga-example"
  # }
}

# for aws_instance
# output "instance_public_ip" {
#   value       = aws_instance.example.public_ip
#   description = "The public ip address the web server"
# }

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  max_size = 10
  min_size = 2

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_security_group" "alb" {
  name = "sunaga-alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}
