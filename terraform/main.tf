provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

resource "aws_instance" "lab_nodes" {
  count = var.nodes_count

  instance_type     = "t2.micro"
  ami               = lookup(var.aws_amis, var.aws_region)
  availability_zone = var.aws_avl_zone

  vpc_security_group_ids = [aws_security_group.allow-traffic.id]
  subnet_id              = aws_subnet.lab_subnet[0].id

  key_name = aws_key_pair.lab_keypair.id

  tags = module.lab_labels.tags
}

resource "aws_ebs_volume" "data-vol" {
  availability_zone = var.aws_avl_zone
  size              = 1
  tags = {
    name = "data-volume"
  }
}

resource "aws_volume_attachment" "first-vol" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.data-vol.id
  instance_id = aws_instance.lab_nodes[0].id
}

resource "aws_vpc" "lab" {
  cidr_block = "10.0.0.0/16"
  tags       = module.lab_labels.tags
}

resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab.id
  availability_zone       = var.aws_avl_zone
  cidr_block              = var.cidr-blocks[count.index]
  map_public_ip_on_launch = true

  count = var.subnet_count

  tags = module.lab_labels.tags
}

resource "aws_security_group" "allow-traffic" {
  name        = "allow-traffic"
  description = "allow ssh and http traffic"
  vpc_id      = aws_vpc.lab.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.lab_labels.tags
}

resource "aws_key_pair" "lab_keypair" {
  key_name   = format("%s%s", var.name, "_keypair")
  public_key = file(var.public_key_path)
}

module "lab_labels" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git"
  namespace   = format("kh-lab-%s", var.name)
  environment = "lab"
  name        = format("DevOps-Bootcamp-%s", var.name)
  attributes  = ["public"]
  delimiter   = "_"
}

resource "aws_instance" "controller_nodes" {
  count = var.controller_count

  instance_type     = "t2.micro"
  ami               = lookup(var.aws_amis, var.aws_region)
  availability_zone = var.aws_avl_zone

  vpc_security_group_ids = [aws_security_group.allow-traffic.id]
  subnet_id              = aws_subnet.lab_subnet[1].id

  key_name = aws_key_pair.lab_keypair.id

  tags = module.lab_labels.tags
}

resource "aws_elb" "lab_elb_web" {
  name            = format("%selb", var.name)
  subnets         = [aws_subnet.lab_subnet[0].id]
  security_groups = [aws_security_group.allow-traffic.id]
  instances       = aws_instance.lab_nodes.*.id

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = module.lab_labels.tags
}

resource "aws_internet_gateway" "lab_gateway" {
  vpc_id = aws_vpc.lab.id
  tags   = module.lab_labels.tags
}

resource "aws_route" "lab_internet_access" {
  route_table_id         = aws_vpc.lab.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab_gateway.id
}

resource "aws_eip" "lab_eip" {
  instance = "aws_instance.lab_nodes[0].id"
  vpc      = true
}