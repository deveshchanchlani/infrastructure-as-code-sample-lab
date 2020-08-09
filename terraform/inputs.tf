variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_region" {
  description = "Oregon"
  default     = "us-west-2"
}

# Ubuntu Server 18.04 LTS 
variable "aws_amis" {
  description = "Ubuntu AMI Created through Packer"
  default = {
    us-west-2 = "ami-0aa81c9cd2a33e33c"
  }
}

variable "aws_avl_zone" {
  default = "us-west-2c"
}

variable "nodes_count" {
  default = 3
}

variable "public_key_path" {
  description = "path to public key to inject into the instances to allow ssh"
  default     = "~/.ssh/id_rsa.pub"
}

variable "name" {
  description = "A name to be applied to make everything unique and personal"
  default     = "lab"
}

variable "controller_count" {
  default = 2
}

variable "subnet_count" {
  default = 2
}

variable "cidr-blocks" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}