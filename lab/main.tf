module "tags_network" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  delimiter   = "_"

	tags = {
    owner       = var.name
    type        = "network"
	}
}

module "tags_bastion" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  delimiter   = "_"

	tags = {
    owner       = var.name
    type        = "bastion"
	}
}

module "tags_worker" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  delimiter   = "_"

	tags = {
    owner       = var.name
    type        = "worker"
	}
}

module "tags_controlplane" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  delimiter   = "_"

	tags = {
    owner       = var.name
    type        = "controlplane"
	}
}

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
  tags       = module.tags_network.tags
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_network.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.lab.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab_gateway.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "bastion" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tags_bastion.tags
}

resource "aws_subnet" "worker" {
	count = 2
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = format("10.0.%s.0/24", count.index + 10)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.tags_worker.tags
}

resource "aws_subnet" "controlplane" {
	count = 2
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = format("10.0.%s.0/24", count.index + 20)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = module.tags_controlplane.tags
}

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_bastion.tags

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "controlplane" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_controlplane.tags

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
}

resource "aws_security_group" "worker" {
  vpc_id = aws_vpc.lab.id
  tags   = module.tags_worker.tags

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.controlplane.id]
  }
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s%s", var.name, "_keypair")
  public_key = file(var.public_key_path)
}

resource "aws_launch_configuration" "worker" {
  image_id        = "ami-02c7c728a7874ae7a"
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.worker.id]
  key_name        = aws_key_pair.lab_keypair.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "workers" {
  max_size                  = 3
  min_size                  = 2
  launch_configuration      = aws_launch_configuration.worker.name
  health_check_grace_period = 300

  health_check_type = "EC2"

  vpc_zone_identifier = aws_subnet.worker.*.id

  target_group_arns = [aws_lb_target_group.asg.arn]

	tag {
		key = "owner"
		value = var.name
    propagate_at_launch = true
	}

	tag {
		key = "type"
		value = "worker"
    propagate_at_launch = true
	}
 
	tag {
		key = "environment"
		value = "dev"
    propagate_at_launch = true
	}
 
	tag {
		key = "name"
		value = format("%s-devops-bootcamp-worker_node", var.name)
    propagate_at_launch = true
	}
 

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "elb" {
  load_balancer_type = "application"

  subnets         = aws_subnet.worker.*.id
  security_groups = [aws_security_group.worker.id]
}

resource "aws_lb_target_group" "asg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab.id
}

resource "aws_autoscaling_attachment" "asg" {
  autoscaling_group_name = aws_autoscaling_group.workers.id
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

resource "aws_instance" "controlplane" {
	count = 2
  ami           = "ami-02c7c728a7874ae7a"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.controlplane[count.index].id
	security_groups = [aws_security_group.controlplane.id]
  key_name      = aws_key_pair.lab_keypair.id
  tags          = module.tags_controlplane.tags
}

resource "aws_instance" "bastion" {
  ami           = "ami-02c7c728a7874ae7a"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.bastion.id
	security_groups = [aws_security_group.bastion.id]
  key_name      = aws_key_pair.lab_keypair.id
  tags          = module.tags_bastion.tags
}

