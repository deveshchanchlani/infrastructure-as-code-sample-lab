module "tags_network" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  attributes  = ["network"]
  delimiter   = "_"
}

module "tags_bastion" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  attributes  = ["bastion"]
  delimiter   = "_"
}

module "tags_worker" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  attributes  = ["worker"]
  delimiter   = "_"
}

module "tags_controlplane" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = var.name
  environment = "dev"
  name        = "devops-bootcamp"
  attributes  = ["controlplane"]
  delimiter   = "_"
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
  tags                    = module.tags_network.tags
}

resource "aws_subnet" "worker_1" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tags_network.tags
}

resource "aws_subnet" "worker_2" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags                    = module.tags_network.tags
}

resource "aws_subnet" "controlplane_1" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags                    = module.tags_network.tags
}

resource "aws_subnet" "controlplane_2" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags                    = module.tags_network.tags
}

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.lab.id

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

  vpc_zone_identifier = [aws_subnet.worker_1.id, aws_subnet.worker_2.id]

  target_group_arns = [aws_lb_target_group.asg.arn]

  tag {
    key                 = "name"
    value               = "workers"
    propagate_at_launch = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "elb" {
  name               = "workerselb"
  load_balancer_type = "application"

  subnets         = [aws_subnet.worker_1.id, aws_subnet.worker_2.id]
  security_groups = [aws_security_group.worker.id]
}

resource "aws_lb_target_group" "asg" {
  name     = "workertg"
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

resource "aws_instance" "controlplane_1" {
  ami           = "ami-02c7c728a7874ae7a"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.controlplane_1.id
	security_groups = [aws_security_group.controlplane.id]
  key_name      = aws_key_pair.lab_keypair.id
  tags          = module.tags_controlplane.tags
}

resource "aws_instance" "controlplane_2" {
  ami           = "ami-02c7c728a7874ae7a"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.controlplane_2.id
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


