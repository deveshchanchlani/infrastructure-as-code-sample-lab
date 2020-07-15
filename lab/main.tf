module "tag_generator" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = format("kh-lab-%s", var.name)
  environment = var.name
  name        = format("DevOps-Bootcamp-%s", var.name)
  attributes  = ["public"]
  delimiter   = "_"
}

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
  tags       = module.tag_generator.tags
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tag_generator.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.lab.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab_gateway.id
}

resource "aws_subnet" "lab_subnet_1" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tag_generator.tags
}

resource "aws_subnet" "lab_subnet_2" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags                    = module.tag_generator.tags
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s%s", var.name, "_keypair")
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "alb-sec-group" {
  name   = "alb-sec-group"
  vpc_id = aws_vpc.lab.id
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
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
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_sec_group" {
  name   = "asg_sec_group"
  vpc_id = aws_vpc.lab.id

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.alb-sec-group.id]
  }
}

resource "aws_launch_configuration" "ec2_template" {
  image_id        = "ami-0f132f5f9da420fd1"
  instance_type   = "t3.micro"
  user_data       = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install -y httpd
            echo "Website is Working !" > /var/www/html/index.html
            systemctl start httpd
            systemctl enable httpd
            EOF
  security_groups = [aws_security_group.asg_sec_group.id]
  key_name        = aws_key_pair.lab_keypair.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "myasg" {
  max_size                  = 5
  min_size                  = 2
  launch_configuration      = aws_launch_configuration.ec2_template.name
  health_check_grace_period = 300

  health_check_type = "ELB"

  vpc_zone_identifier = [aws_subnet.lab_subnet_1.id, aws_subnet.lab_subnet_2.id]

  target_group_arns = [aws_lb_target_group.asg.arn]

  tag {
    key                 = "name"
    value               = "myasg"
    propagate_at_launch = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "elb" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"

  subnets         = [aws_subnet.lab_subnet_1.id, aws_subnet.lab_subnet_2.id]
  security_groups = [aws_security_group.alb-sec-group.id]
}

resource "aws_lb_target_group" "asg" {
  name     = "asg-example"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab.id

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

resource "aws_autoscaling_attachment" "asg" {
  autoscaling_group_name = aws_autoscaling_group.myasg.id
  alb_target_group_arn   = aws_lb_target_group.asg.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.elb.arn
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

  action {
    target_group_arn = aws_lb_target_group.asg.arn
    type             = "forward"
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
